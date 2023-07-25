# ErrorTrackingOpenAPI::ErrorUpdatePayload

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **status** | **String** | Status of the error | [optional] |
| **updated_by_id** | **Integer** | GitLab user id who triggered the update | [optional] |

## Example

```ruby
require 'error_tracking_open_api'

instance = ErrorTrackingOpenAPI::ErrorUpdatePayload.new(
  status: null,
  updated_by_id: null
)
```

