---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Dynamic Element Validation

We devised a solution to solve common test automation problems such as the dreaded `NoSuchElementException`.

Other problems that dynamic element validations solve are...

- When we perform an action with the mouse, we expect something to occur.
- When our test is navigating to (or from) a page, we ensure that we are on the page we expect before
  test continuation.

## How it works

We interpret user actions on the page to have some sort of effect. These actions are

- [Navigation](#navigation)
- [Clicks](#clicks)

### Navigation

When a page is navigated to, there are elements that always appear on the page unconditionally.

Dynamic element validation is instituted when using

```ruby
Runtime::Browser.visit(:gitlab, Some::Page)
```

### Clicks

When we perform a click within our tests, we expect something to occur. That something could be a component to now
appear on the webpage, or the test to navigate away from the page entirely.

Dynamic element validation is instituted when using

```ruby
click_element(:my_element, Some::Page)
```

### Required Elements

#### Definition

First it is important to define what a "required element" is.

Simply put, a required element is a visible HTML element that appears on a UI component without any user input.

"Visible" can be defined as

- Not having any CSS preventing its display. E.g.: `display: none` or `width: 0px; height: 0px;`
- Being able to be interacted with by the user

"UI component" can be defined as

- Anything the user sees
- A button, a text field
- A layer that sits atop the page

#### Application

Requiring elements is very easy. By adding `required: true` as a parameter to an `element`, you've now made it
a requirement that the element appear on the page upon navigation.

## Examples

Given ...

```ruby
class MyPage < Page::Base
  view 'app/views/view.html.haml' do
    element :my_element, required: true
    element :another_element, required: true
    element :conditional_element
  end

  def open_layer
    click_element(:my_element, Layer::MyLayer)
  end
end

class Layer < Page::Component
  view 'app/views/mylayer/layer.html.haml' do
    element :message_content, required: true
  end
end
```

### Navigating

Given the [source](#examples) ...

```ruby
Runtime::Browser.visit(:gitlab, Page::MyPage)

execute_stuff
```

invokes GitLab QA to scan `MyPage` for `my_element` and `another_element` to be on the page before continuing to
`execute_stuff`

### Clicking

Given the [source](#examples) ...

```ruby
def open_layer
  click_element(:my_element, Layer::MyLayer)
end
```

invokes GitLab QA to ensure that `message_content` appears on
the Layer upon clicking `my_element`.

This implies that the Layer is indeed rendered before we continue our test.
