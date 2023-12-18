# frozen_string_literal: true

module QA
  module Vendor
    module Snowplow
      module ProductAnalytics
        class Event
          include Scenario::Actable
          include Support::API

          def send(sdk_host, payload)
            response = post(
              "#{sdk_host}/com.snowplowanalytics.snowplow/tp2",
              payload,
              headers: {
                'Content-Type': 'application/json'
              }
            )

            log("Sending snowplow event to #{sdk_host}. Response: #{response.code} #{response.body}")
          end

          def build_payload(sdk_app_id)
            time_now = (Time.now.to_f * 1000).to_i
            payload_hash = JSON.parse(template_payload)
            payload_hash["data"][0]["aid"] = sdk_app_id
            payload_hash["data"][0]["ue_px"] = ue_px
            payload_hash["data"][0]["cx"] = cx
            payload_hash["data"][0]["dtm"] = time_now.to_s
            payload_hash["data"][0]["stm"] = (time_now + 1).to_s
            payload_hash.to_json
          end

          private

          # Log message
          #
          # @param [String] msg
          # @param [Symbol] level
          # @return [void]
          def log(msg, level = :info)
            QA::Runtime::Logger.public_send(level, msg)
          end

          def template_payload
            '{"schema":"iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-4",
            "data":[{
                "e":"ue",
                "eid":"12345678-1234-1234-1234-123456789012",
                "tv":"js-3.12.0",
                "tna":"gitlab",
                "aid":"placeholder",
                "p":"web",
                "cookie":"1",
                "cs":"UTF-8",
                "lang":"en-US",
                "res":"1728x1117",
                "cd":"30",
                "dtm":"placeholder",
                "vp":"1728x462",
                "ds":"1728x462",
                "vid":"7",
                "sid":"12345678-1234-1234-1234-123456789012",
                "duid":"12345678-1234-1234-1234-123456789012",
                "url":"http://localhost:8080/",
                "ue_px":"placeholder",
                "cx":"placeholder",
                "stm":"placeholder"}
            ]}'
          end

          def ue_px
            Base64.encode64('{"schema":"iglu:com.snowplowanalytics.snowplow/unstruct_event/jsonschema/1-0-0",
                              "data":{
                              "schema":"iglu:com.gitlab/custom_event/jsonschema/1-0-0",
                              "data":{"name":"custom_event","props":{"key1":"value1"}}
                              }
                            }'
                           )
          end

          def cx
            time_now = (Time.now.to_f * 1000).to_i
            payload_hash = JSON.parse(cx_template_payload)
            payload_hash = cx_set_base_timings(time_now, payload_hash)
            payload_hash = cx_set_request_timings(time_now, payload_hash)
            payload_hash = cx_set_dom_timings(time_now, payload_hash)
            payload_hash = cx_set_event_load_timings(time_now, payload_hash)
            payload = payload_hash.to_json

            Base64.encode64(payload)
          end

          def cx_set_base_timings(time, payload_hash)
            payload_hash["data"][2]["data"]["navigationStart"] = time
            payload_hash["data"][2]["data"]["fetchStart"] = time
            payload_hash["data"][2]["data"]["domainLookupStart"] = time
            payload_hash["data"][2]["data"]["domainLookupEnd"] = time
            payload_hash["data"][2]["data"]["connectStart"] = time
            payload_hash["data"][2]["data"]["connectEnd"] = time
            payload_hash
          end

          def cx_set_request_timings(time, payload_hash)
            payload_hash["data"][2]["data"]["requestStart"] = time + 10
            payload_hash["data"][2]["data"]["responseStart"] = time + 20
            payload_hash["data"][2]["data"]["responseEnd"] = time + 20
            payload_hash
          end

          def cx_set_dom_timings(time, payload_hash)
            payload_hash["data"][2]["data"]["domLoading"] = time + 30
            payload_hash["data"][2]["data"]["domInteractive"] = time + 50
            payload_hash["data"][2]["data"]["domContentLoadedEventStart"] = time + 50
            payload_hash["data"][2]["data"]["domContentLoadedEventEnd"] = time + 52
            payload_hash["data"][2]["data"]["domComplete"] = time + 52
            payload_hash
          end

          def cx_set_event_load_timings(time, payload_hash)
            payload_hash["data"][2]["data"]["loadEventStart"] = time + 52
            payload_hash["data"][2]["data"]["loadEventEnd"] = time + 52
            payload_hash
          end

          def cx_template_payload
            '{"schema":"iglu:com.snowplowanalytics.snowplow/contexts/jsonschema/1-0-0",
              "data":[
                {"schema":"iglu:com.snowplowanalytics.snowplow/web_page/jsonschema/1-0-0",
                  "data":{"id":"12345678-1234-1234-1234-123456789123"}
                },
                {"schema":"iglu:com.snowplowanalytics.snowplow/browser_context/jsonschema/1-0-0",
                  "data":{"viewport":"1687x417",
                  "documentSize":"1687x417",
                  "resolution":"1728x1117",
                  "colorDepth":30,
                  "devicePixelRatio":2,
                  "cookiesEnabled":true,
                  "online":true,
                  "browserLanguage":"en-US",
                  "documentLanguage":"en",
                  "webdriver":false,
                  "hardwareConcurrency":12,
                  "tabId":"12345678-1234-1234-1234-123456789123"}
                },
                {"schema":"iglu:org.w3/PerformanceTiming/jsonschema/1-0-0",
                  "data":{"navigationStart":1699963871632,
                  "redirectStart":0,
                  "redirectEnd":0,
                  "fetchStart":1699963871632,
                  "domainLookupStart":1699963871632,
                  "domainLookupEnd":1699963871632,
                  "connectStart":1699963871632,
                  "secureConnectionStart":0,
                  "connectEnd":1699963871632,
                  "requestStart":1699963871642,
                  "responseStart":1699963871653,
                  "responseEnd":1699963871653,
                  "unloadEventStart":0,
                  "unloadEventEnd":0,
                  "domLoading":1699963871660,
                  "domInteractive":1699963871723,
                  "domContentLoadedEventStart":1699963871723,
                  "domContentLoadedEventEnd":1699963871725,
                  "domComplete":1699963871725,
                  "loadEventStart":1699963871725,
                  "loadEventEnd":1699963871725}
                }
              ]
            }'
          end
        end
      end
    end
  end
end
