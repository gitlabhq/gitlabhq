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
    if (!this.prototype.singleton) {
      this.init();
      this.prototype.singleton = this;
    }
    return this.prototype.singleton;
  }

  init() {
    this.prop1 = 'hello';
  }

  method1() {}
}

```

## Manipulating the DOM in a JS Class

When writing a class that needs to manipulate the DOM, guarantee a container element is provided
and avoid DOM queries where possible unless you are querying elements created by the class itself.

Bad:
```javascript
class Foo {
  constructor() {
    this.container = document.getElementById('container');
  }
}

new Foo();
```

Good:
```javascript
class Foo {
  constructor(container) {
    this.container = container;
  }
}

new Foo(document.getElementById('container'));
```

If the query for the container is hard coded in the class, the code is not easily
reusable as you have to match your DOM with the DOM **required** by the class. Additionally,
it is easier to write tests for classes that don't perform queries as you don't have to 
mock the query methods or provide a test DOM.

If the query for the container uses a selector string passed to the constructor, it is
no longer coupled to a specific DOM, but it still lacks the benefits of avoiding that
query all together and leaving the querying to the module that instantiates that class,
which in many cases will be `dispatcher.js`.
