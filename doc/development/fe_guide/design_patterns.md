# Design Patterns

## Singletons

When exactly one object is needed for a given task, prefer to define it as a
`class` rather than as an object literal. Prefer also to explicitly restrict
instantiation, unless flexibility is important (e.g. for testing).

```javascript
// bad

const MyThing = {
  prop1: 'hello',
  method1: () => {}
};

export default MyThing;

// good

class MyThing {
  constructor() {
    this.prop1 = 'hello';
  }
  method1() {}
}

export default new MyThing();

// best

export default class MyThing {
  constructor() {
    if (!MyThing.prototype.singleton) {
      this.init();
      MyThing.prototype.singleton = this;
    }
    return MyThing.prototype.singleton;
  }

  init() {
    this.prop1 = 'hello';
  }

  method1() {}
}

```

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

[container-class-example]: https://gitlab.com/gitlab-org/gitlab/blob/master/app/assets/javascripts/mini_pipeline_graph_dropdown.js
