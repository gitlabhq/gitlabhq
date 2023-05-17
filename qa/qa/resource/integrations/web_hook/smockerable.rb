# frozen_string_literal: true

module QA
  module Resource
    module Integrations
      module WebHook
        module Smockerable
          def teardown!
            Service::DockerRun::Smocker.teardown!
          end

          def setup(mock = Vendor::Smocker::SmockerApi::DEFAULT_MOCK, session: nil, **event_args)
            Service::DockerRun::Smocker.init(wait: 10) do |smocker|
              smocker.register(mock, session: session)

              webhook = fabricate_via_api! do |hook|
                hook.url = smocker.url

                event_args.each do |event, bool|
                  hook.send("#{event}_events=", bool)
                end

                hook
              end

              def smocker.events(session_id = nil)
                history(session_id).map do |history_response|
                  history_response.request.fetch(:body, {})
                end
              end

              yield(webhook, smocker)

              smocker.reset
            end
          end
        end
      end
    end
  end
end
