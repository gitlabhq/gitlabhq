# Design Patterns

## Manipulating the DOM in a JS Class

When writing a class that needs to manipulate the DOM guarantee a container option is provided.
This is useful when we need that class to be instantiated more than once in the same page.

Bad:
```javascript
class Foo {
  constructor() {
    document.querySelector('.bar');
  }
}
new Foo();
```

Good:
```javascript
class Foo {
  constructor(opts) {
    document.querySelector(`${opts.container} .bar`);
  }
}

new Foo({ container: '.my-element' });
```
You can find an example of the above in this [class][container-class-example];


[container-class-example]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/mini_pipeline_graph_dropdown.js
