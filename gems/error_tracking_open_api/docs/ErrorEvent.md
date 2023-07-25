# ErrorTrackingOpenAPI::ErrorEvent

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **fingerprint** | **Integer** |  | [optional] |
| **project_id** | **Integer** |  | [optional] |
| **payload** | **String** | JSON encoded string | [optional] |
| **name** | **String** |  | [optional] |
| **description** | **String** |  | [optional] |
| **actor** | **String** |  | [optional] |
| **environment** | **String** |  | [optional] |
| **platform** | **String** |  | [optional] |

## Example

```ruby
require 'error_tracking_open_api'

instance = ErrorTrackingOpenAPI::ErrorEvent.new(
  fingerprint: null,
  project_id: null,
  payload: null,
  name: ActionView::MissingTemplate,
  description: Missing template posts/edit,
  actor: PostsController#edit,
  environment: production,
  platform: ruby
)
```

