---
stage: Monitor
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Browser SDK
---

This SDK is for instrumenting web sites and applications to send data for the GitLab [product analytics functionality](../_index.md).

## How to use the Browser SDK

### Using the NPM package

Add the NPM package to your package JSON using your preferred package manager:

::Tabs

:::TabTitle yarn

```shell
yarn add @gitlab/application-sdk-browser
```

:::TabTitle npm

```shell
npm i @gitlab/application-sdk-browser
```

::EndTabs

Then, for browser usage import the client SDK:

```javascript
import { glClientSDK } from '@gitlab/application-sdk-browser';

this.glClient = glClientSDK({ appId, host });
```

### Using the script directly

Add the script to the page and assign the client SDK to `window`:

```html
<script src="https://unpkg.com/@gitlab/application-sdk-browser/dist/gl-sdk.min.js"></script>
<script>
  window.glClient = window.glSDK.glClientSDK({
    appId: 'YOUR_APP_ID',
    host: 'YOUR_HOST',
  });
</script>
```

You can use a specific version of the SDK like this:

```html
<script src="https://unpkg.com/@gitlab/application-sdk-browser@0.2.5/dist/gl-sdk.min.js"></script>
```

## Browser SDK initialization options

Apart from `appId` and `host`, you can configure the Browser SDK with the following options:

```typescript
interface GitLabClientSDKOptions {
  appId: string;
  host: string;
  hasCookieConsent?: boolean;
  trackerId?: string;
  pagePingTracking?:
    | boolean
    | {
        minimumVisitLength?: number;
        heartbeatDelay?: number;
      };
  plugins?: AllowedPlugins;
}
```

| Option                        | Description |
| :---------------------------- | :---------- |
| `appId`                       | The ID provided by the GitLab Project Analytics setup guide. This ID ensures your data is sent to your analytics instance. |
| `host`                        | The GitLab Project Analytics instance provided by the setup guide. |
| `hasCookieConsent`            | Whether to use cookies to identify unique users. Set to `false` by default. When `false`, users are considered anonymous users. No cookies or other storage mechanisms are used to identify users. |
| `trackerId`                   | Used to differentiate between multiple trackers running on the same page or application, because each tracker instance can be configured differently to capture different sets of data. This identifier helps ensure that the data sent to the collector is correctly associated with the correct tracker configuration. Default value is `gitlab`. |
| `pagePingTracking`            | Option to track user engagement on your website or application by sending periodic events while a user is actively browsing a page. Page pings provide valuable insight into how users interact with your content, such as how long they spend on a page, which sections they are viewing, and whether they are scrolling. `pagePingTracking` can be boolean or an object. As a boolean, set to `true` it enables page ping with default options, and set to `false` it disables page ping tracking. As an object, it has two options: `minimumVisitLength` (the minimum time that must have elapsed before the first heartbeat) and `heartbeatDelay` (the interval at which the callback is fired). |
| `plugins`                     | Specify which plugins to enable or disable. By default all plugins are enabled. |

### Plugins

- `Client Hints`: An alternative to tracking the User Agent, which is particularly useful in browsers that are freezing the User Agent string.
  Enabling this plugin will automatically capture the following context:

  For example,
  [iglu:org.ietf/http_client_hints/jsonschema/1-0-0](https://github.com/snowplow/iglu-central/blob/master/schemas/org.ietf/http_client_hints/jsonschema/1-0-0)
  has the following configuration:

  ```json
  {
     "isMobile":false,
     "brands":[
        {
           "brand":"Google Chrome",
           "version":"89"
        },
        {
           "brand":"Chromium",
           "version":"89"
        }
     ]
  }
  ```

- `Link Click Tracking`: With this plugin, the tracker adds click event listeners to all link elements. Link clicks are tracked as self-describing events. Each link-click event captures the link's `href` attribute. The event also has fields for the link's ID, classes, and target (where the linked document is opened, such as a new tab or new window).

- `Performance Timing`: It collects performance-related data from a user's browser using the `Navigation Timing API`. This API provides detailed information about the various stages of loading a web page, such as domain lookup, connection time, content download, and rendering times. This plugin helps to gather insights into how well a website performs for users, identify potential performance bottlenecks, and improve the overall user experience.

- `Error Tracking`: It helps to capture and track errors that occur on a website or application. By monitoring these errors, you can gain insights into potential issues with code or third-party libraries, which can help to improve the overall user experience, and maintain the quality of the website or application.

By default all plugins are enabled. You can disable or enable these plugins through the `plugins` object:

```typescript
const tracker = glClientSDK({
  ...options,
  plugins: {
    clientHints: true,
    linkTracking: true,
    performanceTiming: true,
    errorTracking: true,
  },
});
```

## Methods

### `identify`

Used to associate a user and their attributes with the session and tracking events.

```javascript
glClient.identify(userId, userAttributes);
```

| Property         | Type                        | Description                                                                   |
| :--------------- | :-------------------------- | :---------------------------------------------------------------------------- |
| `userId`         | `String`                    | The user identifier your application uses to identify individual users. |
| `userAttributes` | `Object`/`Null`/`undefined` | The user attributes that need to be added to the session and tracking events. |

### `page`

Used to trigger a pageview event.

```javascript
glClient.page(eventAttributes);
```

| Property          | Type                        | Description                                                       |
| :---------------- | :-------------------------- | :---------------------------------------------------------------- |
| `eventAttributes` | `Object`/`Null`/`undefined` | The event attributes that need to be added to the pageview event. |

The `eventAttributes` object supports the following optional properties:

| Property          | Type        | Description |
|:------------------|:------------|:------------|
| `title`           | `String`    | Override the default page title. |
| `contextCallback` | `Function`  | A callback that fires on the page view. |
| `context`         | `Object`    | Add context (additional information) on the page view. |
| `timestamp`       | `timestamp` | Set the true timestamp or overwrite the device-sent timestamp on an event. |

### `track`

Used to trigger a custom event.

```javascript
glClient.track(eventName, eventAttributes);
```

| Property          | Type                        | Description                                                      |
| :---------------- | :-------------------------- | :--------------------------------------------------------------- |
| `eventName`       | `String`                    | The name of the custom event.                                    |
| `eventAttributes` | `Object`/`Null`/`undefined` | The event attributes that need to be added to the tracked event. |

### `refreshLinkClickTracking`

`enableLinkClickTracking` tracks only clicks on links that exist when the page has loaded. To track new links added to the page after it has been loaded, use `refreshLinkClickTracking`.

```javascript
glClient.refreshLinkClickTracking();
```

### `trackError`

NOTE:
`trackError` is supported on the Browser SDK, but the resulting events are not used or available.

Used to capture errors. This works only when the `errorTracking` plugin is enabled. The [plugin](#plugins) is enabled by default.

```javascript
glClient.trackError(eventAttributes);
```

For example, `trackError` can be used in `try...catch` like below:

```javascript
try {
  // Call the function that throws an error
  throwError();
} catch (error) {
  glClient.trackError({
    message: error.message, // "This is a custom error"
    filename: error.fileName || 'unknown', // The file in which the error occurred (e.g., "index.html")
    lineno: error.lineNumber || 0, // The line number where the error occurred (e.g., 2)
    colno: error.columnNumber || 0, // The column number where the error occurred (e.g., 6)
    error: error, // The Error object itself
  });
}
```

| Property          | Type     | Description                                                                                                          |
| :---------------- | :------- | :------------------------------------------------------------------------------------------------------------------- |
| `eventAttributes` | `Object` | The event attributes that need to be added to the tracked event. `message` is a mandatory key in `eventAttributes`. |

### `addCookieConsent`

`addCookieConsent` is used to allow tracking of user identifiers via cookies. By default `hasCookieConsent` is false, and no user identifiers are passed. To enable tracking of user identifiers, call the `addCookieConsent` method. This step is not needed if you initialized the Browser SDK with `hasCookieConsent` set to true.

```javascript
glClient.addCookieConsent();
```

### `setCustomUrl`

Used to set a custom URL for tracking.

```javascript
glClient.setCustomUrl(url);
```

| Property | Type     | Description                                       |
| :------- | :------- | :------------------------------------------------ |
| `url`    | `String` | The custom URL that you want to set for tracking. |

### `setReferrerUrl`

Used to set a referrer URL for tracking.

```javascript
glClient.setReferrerUrl(url);
```

| Property | Type     | Description                                         |
| :------- | :------- | :-------------------------------------------------- |
| `url`    | `String` | The referrer URL that you want to set for tracking. |

### `setDocumentTitle`

Used to override the document title.

```javascript
glClient.setDocumentTitle(title);
```

| Property | Type     | Description                        |
| :------- | :------- | :--------------------------------- |
| `title`  | `String` | The document title you want to set. |

## Contribute

If you would like to contribute to Browser SDK, follow the [contributing guide](https://gitlab.com/gitlab-org/analytics-section/product-analytics/gl-application-sdk-js/-/blob/main/docs/Contributing.md).

## Troubleshooting

If the Browser SDK is not sending events, or behaving in an unexpected way, take the following actions:

1. Verify that the `appId` and host values in the options object are correct.
1. Check if any browser privacy settings, extensions, or ad blockers are interfering with the Browser SDK.

For more information and assistance, see the [Snowplow documentation](https://docs.snowplow.io/docs/collecting-data/collecting-from-own-applications/javascript-trackers/web-tracker/)
or contact the [Analytics Instrumentation team](https://handbook.gitlab.com/handbook/engineering/development/analytics/analytics-instrumentation/#team-members).
