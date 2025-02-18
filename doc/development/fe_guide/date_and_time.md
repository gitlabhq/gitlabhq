---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Date and time
---

## Formatting

Our design guidelines, [Pajamas, states](https://design.gitlab.com/content/date-and-time):

> We can either display a localized time and date format based on the user's location or use a non-localized format following the ISO 8601 standard.

When formatting dates for the UI, use the `localeDateFormat` singleton as this localizes dates based on the user's locale preferences.
The logic for getting the locale is in the `getPreferredLocales` function in `app/assets/javascripts/locale/index.js`.

Avoid using the `formatDate` and `dateFormat` date utility functions as they do not format dates in a localized way.

```javascript
// good
const formattedDate = localeDateFormat.asDate.format(date);

// bad
const formattedDate = formatDate(date);
const formattedDate = dateFormat(date);
```

## Gotchas

When working with dates, you might encounter unexpected behavior.

### Date-only bug

There is a bug when passing a string of the format `yyyy-mm-dd` to the `Date` constructor.

From the [MDN Date page](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date):

> When the time zone offset is absent, **date-only forms are interpreted as a UTC time and date-time forms are interpreted as local time**.
This is due to a historical spec error that was not consistent with ISO 8601 but could not be changed due to web compatibility.

When doing `new Date('2020-02-02')`, you might expect this to create a date like `Sun Feb 02 2020 00:00:00` in your local time.
However, due to this date-only bug, `new Date('2020-02-02')` is interpreted as UTC.
For example, if your time zone is UTC-8, this creates the date object at UTC (`Sun Feb 02 2020 00:00:00 UTC`) instead of local UTC-8 timezone, and is then converted to local UTC-8 timezone (`Sat Feb 01 2020 16:00:00 GMT-0800 (Pacific Standard Time)`).
When in a time zone behind UTC, this causes the parsed date to become a day behind, resulting in unexpected bugs.

There are a few ways to convert a date-only string to keep the same date:

- Use the `newDate` function, created specifically to avoid this bug, which is a wrapper around the `Date` constructor.
- Include a time component in the string.
- Use the `(year, month, day)` constructor.

Ideally, use the `newDate` function when creating a `Date` object so you don't have to worry about this bug.

```javascript
// good

// use the newDate function
import { newDate } from '~/lib/utils/datetime_utility';
newDate('2020-02-02') // Sun Feb 02 2020 00:00:00 GMT-0800 (Pacific Standard Time)

// add a time component
new Date('2020-02-02T00:00') // Sun Feb 02 2020 00:00:00 GMT-0800 (Pacific Standard Time)

// use the (year, month, day) constructor - note that month is 0-indexed (another source of possible bugs, yay!)
new Date(2020, 1, 2) // Sun Feb 02 2020 00:00:00 GMT-0800 (Pacific Standard Time)

// bad

// date-only string
new Date('2020-02-02') // Sat Feb 01 2020 16:00:00 GMT-0800 (Pacific Standard Time)

// using the static parse method with a date-only string
new Date(Date.parse('2020-02-02')) // Sat Feb 01 2020 16:00:00 GMT-0800 (Pacific Standard Time)

// using the static UTC method
new Date(Date.UTC(2020, 1, 2)) // Sat Feb 01 2020 16:00:00 GMT-0800 (Pacific Standard Time)
```

### Date picker

The `GlDatepicker` component returns a `Date` object at midnight local time.
This can cause issues in time zones ahead of UTC, for example with GraphQL mutations.

For example, in UTC+8:

1. You select `2020-02-02` in the date picker.
1. The `Date` object returned is `Sun Feb 02 2020 00:00:00 GMT+0800 (China Standard Time)` local time.
1. When sent to GraphQL, it's converted to the UTC string `2020-02-01T16:00:00.000Z`, which is a day behind.

To preserve the date, use `toISODateFormat` to convert the `Date` object to a date-only string:

```javascript
const dateString = toISODateFormat(dateObject); // "2020-02-02"
```

## Testing

### Manual testing

When performing manual testing of dates, such as when reviewing merge requests, test with time zones behind and ahead of UTC, such as UTC-8, UTC, and UTC+8, to spot potential bugs.

To change the time zone on macOS:

1. Go to **System Settings > General > Date & Time**.
1. Clear the **Set time zone automatically using your current location** checkbox.
1. Change **Closest city** to a city in another time zone, such as Sacramento, London, or Beijing.

### Jest

Our Jest tests are run with a mocked date of 2020-07-06 for determinism, which can be overridden using the `useFakeDate` function.
The logic for this is in `spec/frontend/__helpers__/fake_date/fake_date.js`.
