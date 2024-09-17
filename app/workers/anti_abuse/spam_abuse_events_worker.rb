# frozen_string_literal: true

module AntiAbuse
  class SpamAbuseEventsWorker
    include ApplicationWorker

    data_consistency :delayed

    idempotent!
    feature_category :instance_resiliency
    urgency :low

    def perform(params)
      params = params.with_indifferent_access

      @user = User.find_by_id(params[:user_id])
      unless @user
        logger.info(structured_payload(message: "User not found.", user_id: params[:user_id]))
        return
      end

      report_user(params)
    end

    private

    attr_reader :user

    def report_user(params)
      category = 'spam'
      reporter = Users::Internal.security_bot
      report_params = { user_id: params[:user_id],
                        reporter: reporter,
                        category: category,
                        message: 'User reported for abuse based on spam verdict' }

      abuse_report = AbuseReport.by_category(category).by_reporter_id(reporter.id).by_user_id(params[:user_id]).first

      abuse_report = AbuseReport.create!(report_params) if abuse_report.nil?

      create_abuse_event(abuse_report.id, params)
    end

    # Associate the abuse report with an abuse event
    def create_abuse_event(abuse_report_id, params)
      AntiAbuse::Event.create!(
        abuse_report_id: abuse_report_id,
        category: :spam,
        metadata: { noteable_type: params[:noteable_type],
                    title: params[:title],
                    description: params[:description],
                    source_ip: params[:source_ip],
                    user_agent: params[:user_agent],
                    verdict: params[:verdict] },
        source: :spamcheck,
        user: user
      )
    end
  end
end
