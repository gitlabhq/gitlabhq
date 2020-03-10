# Unit formats reference

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/201999) in GitLab 12.9.

You can select units to format your charts by adding `format` to your
[axis configuration](prometheus.md#dashboard-yaml-properties).

## Numbers

For generic data, numbers are formatted according to the current locale.

Formats: `number`

**Examples:**

| Data      | Displayed |
| --------- | --------- |
| `10`      | 1         |
| `1000`    | 1,000     |
| `1000000` | 1,000,000 |

## Percentage

For percentage data, format numbers in the chart with a `%` symbol.

Formats supported: `percent`, `percentHundred`

**Examples:**

| Format           | Data  | Displayed |
| ---------------- | ----- | --------- |
| `percent`        | `0.5` | 50%       |
| `percent`        | `1`   | 100%      |
| `percent`        | `2`   | 200%      |
| `percentHundred` | `50`  | 50%       |
| `percentHundred` | `100` | 100%      |
| `percentHundred` | `200` | 200%      |

## Duration

For time durations, format numbers in the chart with a time unit symbol.

Formats supported: `milliseconds`, `seconds`

**Examples:**

| Format         | Data   | Displayed |
| -------------- | ------ | --------- |
| `milliseconds` | `10`   | 10ms      |
| `milliseconds` | `500`  | 100ms     |
| `milliseconds` | `1000` | 1000ms    |
| `seconds`      | `10`   | 10s       |
| `seconds`      | `500`  | 500s      |
| `seconds`      | `1000` | 1000s     |

## Digital (Metric)

Converts a number of bytes using metric prefixes. It scales to
use the unit that's the best fit.

Formats supported:

- `decimalBytes`
- `kilobytes`
- `megabytes`
- `gigabytes`
- `terabytes`
- `petabytes`

**Examples:**

| Format         | Data      | Displayed |
| -------------- | --------- | --------- |
| `decimalBytes` | `1`       | 1B        |
| `decimalBytes` | `1000`    | 1kB       |
| `decimalBytes` | `1000000` | 1MB       |
| `kilobytes`    | `1`       | 1kB       |
| `kilobytes`    | `1000`    | 1MB       |
| `kilobytes`    | `1000000` | 1GB       |
| `megabytes`    | `1`       | 1MB       |
| `megabytes`    | `1000`    | 1GB       |
| `megabytes`    | `1000000` | 1TB       |

## Digital (IEC)

Converts a number of bytes using binary prefixes. It scales to
use the unit that's the best fit.

Formats supported:

- `bytes`
- `kibibytes`
- `mebibytes`
- `gibibytes`
- `tebibytes`
- `pebibytes`

**Examples:**

| Format      | Data          | Displayed |
| ----------- | ------------- | --------- |
| `bytes`     | `1`           | 1B        |
| `bytes`     | `1024`        | 1KiB      |
| `bytes`     | `1024 * 1024` | 1MiB      |
| `kibibytes` | `1`           | 1KiB      |
| `kibibytes` | `1024`        | 1MiB      |
| `kibibytes` | `1024 * 1024` | 1GiB      |
| `mebibytes` | `1`           | 1MiB      |
| `mebibytes` | `1024`        | 1GiB      |
| `mebibytes` | `1024 * 1024` | 1TiB      |
