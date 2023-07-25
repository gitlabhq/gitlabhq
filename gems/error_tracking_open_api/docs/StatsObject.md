# ErrorTrackingOpenAPI::StatsObject

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **start** | **String** | ID of the project | [optional] |
| **_end** | **String** | Name of the project | [optional] |
| **interval** | **Array&lt;String&gt;** | Slug of the project | [optional] |
| **group** | [**Array&lt;StatsObjectGroupInner&gt;**](StatsObjectGroupInner.md) |  | [optional] |

## Example

```ruby
require 'error_tracking_open_api'

instance = ErrorTrackingOpenAPI::StatsObject.new(
  start: null,
  _end: null,
  interval: null,
  group: null
)
```

