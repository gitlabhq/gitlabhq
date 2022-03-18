# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_evidence, class: '::Gitlab::Ci::Reports::Security::Evidence' do
    data do
      {
        summary: 'Credit card detected',
        request: {
          headers: [{ name: 'Accept', value: '*/*' }],
          method: 'GET',
          url: 'http://goat:8080/WebGoat/logout',
          body: nil
        },
        response: {
          headers: [{ name: 'Content-Length', value: '0' }],
          reason_phrase: 'OK',
          status_code: 200,
          body: nil
        },
        source: {
          id: 'assert:Response Body Analysis',
          name: 'Response Body Analysis',
          url: 'htpp://hostname/documentation'
        },
        supporting_messages: [
          {
            name: 'Origional',
            request: {
              headers: [{ name: 'Accept', value: '*/*' }],
              method: 'GET',
              url: 'http://goat:8080/WebGoat/logout',
              body: ''
            }
          },
          {
            name: 'Recorded',
            request: {
              headers: [{ name: 'Accept', value: '*/*' }],
              method: 'GET',
              url: 'http://goat:8080/WebGoat/logout',
              body: ''
            },
            response: {
              headers: [{ name: 'Content-Length', value: '0' }],
              reason_phrase: 'OK',
              status_code: 200,
              body: ''
            }
          }
        ]
      }
    end

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::Evidence.new(**attributes)
    end
  end
end
