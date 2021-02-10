# frozen_string_literal: true

module Members
  class CreateService < Members::BaseService
    include Gitlab::Utils::StrongMemoize

    DEFAULT_LIMIT = 100

    def execute(source)
      return error(s_('AddMember|No users specified.')) if user_ids.blank?

      return error(s_("AddMember|Too many users specified (limit is %{user_limit})") % { user_limit: user_limit }) if
        user_limit && user_ids.size > user_limit

      members = source.add_users(
        user_ids,
        params[:access_level],
        expires_at: params[:expires_at],
        current_user: current_user
      )

      errors = []

      members.each do |member|
        if member.invalid?
          current_error =
            # Invited users may not have an associated user
            if member.user.present?
              "#{member.user.username}: "
            else
              ""
            end

          current_error += member.errors.full_messages.to_sentence
          errors << current_error
        else
          after_execute(member: member)
        end
      end

      return success unless errors.any?

      error(errors.to_sentence)
    end

    private

    def user_ids
      strong_memoize(:user_ids) do
        ids = params[:user_ids] || ''
        ids.split(',').uniq.flatten
      end
    end

    def user_limit
      limit = params.fetch(:limit, DEFAULT_LIMIT)

      limit && limit < 0 ? nil : limit
    end
  end
end

Members::CreateService.prepend_if_ee('EE::Members::CreateService')
