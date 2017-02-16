module API
  module Helpers
    module Runner
      UPDATE_RUNNER_EVERY = 10 * 60

      def runner_registration_token_valid?
        ActiveSupport::SecurityUtils.variable_size_secure_compare(params[:token],
                                                                  current_application_settings.runners_registration_token)
      end

      def get_runner_version_from_params
        return unless params['info'].present?
        attributes_for_keys(%w(name version revision platform architecture), params['info'])
      end

      def authenticate_runner!
        forbidden! unless current_runner
      end

      def current_runner
        @runner ||= ::Ci::Runner.find_by_token(params[:token].to_s)
      end

      def update_runner_info
        return unless update_runner?

        current_runner.contacted_at = Time.now
        current_runner.assign_attributes(get_runner_version_from_params)
        current_runner.save if current_runner.changed?
      end

      def update_runner?
        # Use a random threshold to prevent beating DB updates.
        # It generates a distribution between [40m, 80m].
        #
        contacted_at_max_age = UPDATE_RUNNER_EVERY + Random.rand(UPDATE_RUNNER_EVERY)

        current_runner.contacted_at.nil? ||
          (Time.now - current_runner.contacted_at) >= contacted_at_max_age
      end

      def build_not_found!
        if headers['User-Agent'].to_s.match(/gitlab(-ci-multi)?-runner \d+\.\d+\.\d+(~beta\.\d+\.g[0-9a-f]+)? /)
          no_content!
        else
          not_found!
        end
      end
    end
  end
end
