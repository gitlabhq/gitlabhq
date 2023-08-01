# ErrorTrackingOpenAPI::MessageEvent

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **Integer** |  | [optional] |
| **event_id** | **String** |  | [optional] |
| **timestamp** | **Time** |  | [optional] |
| **level** | **String** |  | [optional] |
| **message** | **String** |  | [optional] |
| **release** | **String** |  | [optional] |
| **environment** | **String** |  | [optional] |
| **platform** | **String** |  | [optional] |

## Example

```ruby
require 'error_tracking_open_api'

instance = ErrorTrackingOpenAPI::MessageEvent.new(
  project_id: null,
  event_id: null,
  timestamp: null,
  level: info,
  message: some message from the SDK,
  release: v1.0.0,
  environment: production,
  platform: ruby
)
```

