---
stage: Analyze
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Browser SDK

This SDK is for instrumenting web sites and applications to send data for the GitLab [product analytics functionality](../index.md).

## How to use the Browser-SDK

### Using the NPM package

Add the NPM package to your package JSON using your preferred package manager:

```shell
yarn add @gitlab/application-sdk-browser
```

OR

```shell
npm i @gitlab/application-sdk-browser
```

Then for browser usage you can import the client SDK:

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

## Browser-SDK initialization options

Apart from `appId` and `host`, the options below allow you to configure the Browser SDK.

```typescript
interface GitLabClientSDKOptions {
  appId: string;
  host: string;
  hasCookieConsent?: boolean;
  respectGlobalPrivacyControl?: boolean;
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

| Option                        | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| :---------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `appId`                       | This is the ID given by the GitLab Project Analytics setup guide. This is used to make sure your data is sent to your analytics instance.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| `host`                        | This is the GitLab Project Analytics instance that is given by the setup guide.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `hasCookieConsent`            | To use cookies to identify unique users and record their full IP address. This is set to `false` by default. When `false`, users will be considered anonymous users. No cookies or other storage mechanisms will be used to identify users.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `respectGlobalPrivacyControl` | To respect the user's [GPC](https://globalprivacycontrol.org/) configuration to permit or refuse tracking. This is set to `true` by default. When `false`, events will be emitted regardless of user configuration.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `trackerId`                   | The `trackerId` is used to differentiate between multiple trackers running on the same page or application, as each tracker instance can be configured differently to capture different sets of data. This identifier helps ensure that the data sent to the collector is correctly associated with the correct tracker configuration. `Default trackerId value is set as gitlab`.                                                                                                                                                                                                                                                                                        |
| `pagePingTracking`            | Page ping is a feature that allows you to `track user engagement on your website or application by sending periodic events while a user is actively browsing a page.` Page pings provide valuable insight into how users interact with your content, such as how long they spend on a page, which sections they are viewing, and if they are scrolling or not. `pagePingTracking` can be boolean or an object. If true it enables page ping with default options. if false, it will not enable page ping tracking. it can also be an object containing two options : `minimumVisitLength` - The minimum time that must have elapsed before first heartbeat. `heartbeatDelay` - The interval at which the callback is fired. |
| `plugins`                     | Specify which plugins to enable or disable. By default all plugins are enabled.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |

### Plugins

- `Client Hints`: It is an alternative the tracking the User Agent, which is particularly useful in those browsers which are freezing the User Agent string.
Enabling this plugin will automatically capture the following context:

| Context                                                                                                                                                      | Example                                                                                                                  |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| [iglu:org.ietf/http_client_hints/jsonschema/1-0-0](https://github.com/snowplow/iglu-central/blob/master/schemas/org.ietf/http_client_hints/jsonschema/1-0-0) | `{"isMobile" : false, "brands" : [{"brand" : "Google Chrome", version : "89"}, {"brand" : "Chromium", version : "89"}]}` |

- `Link Click Tracking`: With this plugin, the tracker will add click event listeners to all link elements. Link clicks are tracked as self-describing events. Each link-click event captures the link’s href attribute. The event also has fields for the link’s ID, classes, and target (where the linked document is opened, such as a new tab or new window).

- `Performance Timing`: It collects performance-related data from a user's browser using the `Navigation Timing API`. This API provides detailed information about the various stages of loading a web page, such as domain lookup, connection time, content download, and rendering times. This plugin helps to gather insights into how well website performs for users, identify potential performance bottlenecks, and improve the overall user experience.

- `Error Tracking`: It helps to capture and track errors that occur on website or application. By monitoring these errors, one can gain insights into potential issues with code or third-party libraries, which can help to improve the overall user experience and maintain the quality of website or application.

`By default all the plugins are enabled`. These plugins can be enabled or disabled through the `plugins` object:

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
| `userId`         | `String`                    | The user identifier your application users to identify individual users.      |
| `userAttributes` | `Object`/`Null`/`undefined` | The user attributes that need to be added to the session and tracking events. |

### `page`

Used to trigger a pageview event.

```javascript
glClient.page(eventAttributes);
```

| Property          | Type                        | Description                                                       |
| :---------------- | :-------------------------- | :---------------------------------------------------------------- |
| `eventAttributes` | `Object`/`Null`/`undefined` | The event attributes that need to be added to the pageview event. |

### `track`

Used to trigger a custom event.

```javascript
glClient.track(eventName, eventAttributes);
```

| Property          | Type                        | Description                                                      |
| :---------------- | :-------------------------- | :--------------------------------------------------------------- |
| `eventName`       | `String`                    | The name of the custom event.                                    |
| `eventAttributes` | `Object`/`Null`/`undefined` | The event attributes that need to be added to the tracked event. |

### refreshLinkClickTracking

enableLinkClickTracking only tracks clicks on links which exist when the page has loaded. If new links can be added to the page after then which you wish to track, just use refreshLinkClickTracking.

```javascript
glClient.refreshLinkClickTracking();
```

### `trackError`

NOTE:
While `trackError` is supported on the Browser SDK the resulting events are currently not yet used or available anywhere.

Used to capture errors. This works only when the `errorTracking` plugin is enabled. As mentioned in [Plugins](#plugins) section, By default it is enabled.

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
| `eventAttributes` | `Object` | The event attributes that need to be added to the tracked event. `messeage` is a mandatory key in `eventAttributes`. |

### `addCookieConsent`

`addCookieConsent` is used to allow tracking of user identifiers via cookies. By default `hasCookieConsent` is false and no user identifiers are passed. To enable tracking of user identifiers call the `addCookieConsent` method. This is not needed if you intialised the Browser SDK with `hasCookieConsent` set to true.

```javascript
glClient.addCookieConsent();
```

### setCustomUrl

Used to set a custom URL for tracking.

```javascript
glClient.setCustomUrl(url);
```

| Property | Type     | Description                                       |
| :------- | :------- | :------------------------------------------------ |
| `url`    | `String` | The custom URL that you want to set for tracking. |

### setReferrerUrl

Used to set a referrer URL for tracking.

```javascript
glClient.setReferrerUrl(url);
```

| Property | Type     | Description                                         |
| :------- | :------- | :-------------------------------------------------- |
| `url`    | `String` | The referrer URL that you want to set for tracking. |

### setDocumentTitle

Used to override document title.

```javascript
glClient.setDocumentTitle(title);
```

| Property | Type     | Description                        |
| :------- | :------- | :--------------------------------- |
| `title`  | `String` | The document title you want to set |

## Contribute

Want to contribute to Browser-SDK? follow [contributing guide](https://gitlab.com/gitlab-org/analytics-section/product-analytics/gl-application-sdk-js/-/blob/main/docs/Contributing.md).

## Troubleshooting

If the Browser SDK is not sending events or is behaving in an unexpected way, take the following actions:

- Verify that the appId and host values in the options object are correct.
- Check if any browser privacy settings, extensions, or ad blockers are interfering with the Browser SDK.

For more information and assistance, consult the [Snowplow documentation](https://docs.snowplow.io/docs/collecting-data/collecting-from-own-applications/javascript-trackers/browser-tracker/browser-tracker-v3-reference/)
or contact the [Analytics Instrumentation](https://about.gitlab.com/handbook/engineering/development/analytics/analytics-instrumentation/#team-members) team.
