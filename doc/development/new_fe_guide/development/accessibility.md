---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Accessibility

Using semantic HTML plays a key role when it comes to accessibility.

## Accessible Rich Internet Applications - ARIA

WAI-ARIA (the Accessible Rich Internet Applications specification) defines a way to make Web content and Web applications more accessible to people with disabilities.

The W3C recommends [using semantic elements](https://www.w3.org/TR/using-aria/#notes2) as the primary method to achieve accessibility rather than adding aria attributes. Adding aria attributes should be seen as a secondary method for creating accessible elements.

### Role

The `role` attribute describes the role the element plays in the context of the document.

Review the list of [WAI-ARIA roles](https://www.w3.org/TR/wai-aria-1.1/#landmark_roles).

## Icons

When using icons or images that aren't absolutely needed to understand the context, we should use `aria-hidden="true"`.

On the other hand, if an icon is crucial to understand the context we should do one of the following:

1. Use `aria-label` in the element with a meaningful description
1. Use `aria-labelledby` to point to an element that contains the explanation for that icon

## Form inputs

In forms we should use the `for` attribute in the label statement:

```html
<div>
  <label for="name">Fill in your name:</label>
  <input type="text" id="name" name="name">
</div>
```

## Testing

1. On MacOS you can use [VoiceOver](https://www.apple.com/accessibility/mac/vision/) by pressing `cmd+F5`.
1. On Windows you can use [Narrator](https://www.microsoft.com/en-us/accessibility/windows) by pressing Windows logo key + Control + Enter.

## Online resources

- [Chrome Accessibility Developer Tools](https://github.com/GoogleChrome/accessibility-developer-tools) for testing accessibility
- [Audit Rules Page](https://github.com/GoogleChrome/accessibility-developer-tools/wiki/Audit-Rules) for best practices
- [Lighthouse Accessibility Score](https://web.dev/performance-scoring/) for accessibility audits
