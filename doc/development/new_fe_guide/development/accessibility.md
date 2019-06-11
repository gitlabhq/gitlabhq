# Accessiblity
Using semantic HTML plays a key role when it comes to accessibility.

## Accessible Rich Internet Applications - ARIA
WAI-ARIA, the Accessible Rich Internet Applications specification, defines a way to make Web content and Web applications more accessible to people with disabilities.

> Note: It is [recommended][using-aria] to use semantic elements as the primary method to achieve accessibility rather than adding aria attributes. Adding aria attributes should be seen as a secondary method for creating accessible elements.

### Role
The `role` attribute describes the role the element plays in the context of the document.

Check the list of WAI-ARIA roles [here][roles]

## Icons
When using icons or images that aren't absolutely needed to understand the context, we should use `aria-hidden="true"`.

On the other hand, if an icon is crucial to understand the context we should do one of the following:

1. Use `aria-label` in the element with a meaningful description
1. Use `aria-labelledby` to point to an element that contains the explanation for that icon

## Form inputs
In forms we should use the `for` attribute in the label statement:

```
<div>
  <label for="name">Fill in your name:</label>
  <input type="text" id="name" name="name">
</div>
```

## Testing

1. On MacOS you can use [VoiceOver][voice-over] by pressing `cmd+F5`.
1. On Windows you can use [Narrator][narrator] by pressing Windows logo key + Ctrl + Enter.

## Online resources

- [Chrome Accessibility Developer Tools][dev-tools] for testing accessibility
- [Audit Rules Page][audit-rules] for best practices
- [Lighthouse Accessibility Score][lighthouse] for accessibility audits

[using-aria]: https://www.w3.org/TR/using-aria/#notes2
[dev-tools]: https://github.com/GoogleChrome/accessibility-developer-tools
[audit-rules]: https://github.com/GoogleChrome/accessibility-developer-tools/wiki/Audit-Rules
[aria-w3c]: https://www.w3.org/TR/wai-aria-1.1/
[roles]: https://www.w3.org/TR/wai-aria-1.1/#landmark_roles
[voice-over]: https://www.apple.com/accessibility/mac/vision/
[narrator]: https://www.microsoft.com/en-us/accessibility/windows
[lighthouse]: https://developers.google.com/web/tools/lighthouse/scoring#a11y
