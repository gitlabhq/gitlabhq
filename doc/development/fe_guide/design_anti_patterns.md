---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Design Anti-patterns

Anti-patterns may seem like good approaches at first, but it has been shown that they bring more ills than benefits. These should
generally be avoided.

Throughout the GitLab codebase, there may be historic uses of these anti-patterns. Please [use discretion](https://about.gitlab.com/handbook/engineering/#balance-refactoring-and-velocity)
when figuring out whether or not to refactor, when touching code that uses one of these legacy patterns.

**Please note:** For new features, anti-patterns are not necessarily prohibited, but it is **strongly suggested** to find another approach.

## Shared Global Object (Anti-pattern)

A shared global object is an instance of something that can be accessed from anywhere and therefore has no clear owner.

Here's an example of this pattern applied to a Vuex Store:

```javascript
const createStore = () => new Vuex.Store({
  actions,
  state,
  mutations
});

// Notice that we are forcing all references to this module to use the same single instance of the store.
// We are also creating the store at import-time and there is nothing which can automatically dispose of it.
//
// As an alternative, we should export the `createStore` and let the client manage the
// lifecycle and instance of the store.
export default createStore();
```

### What problems do Shared Global Objects cause?

Shared Global Objects are convenient because they can be accessed from anywhere. However,
the convenience does not always outweigh their heavy cost:

- **No ownership.** There is no clear owner to these objects and therefore they assume a non-deterministic
  and permanent lifecycle. This can be especially problematic for tests.
- **No access control.** When Shared Global Objects manage some state, this can create some very buggy and difficult
  coupling situations because there is no access control to this object.
- **Possible circular references.** Shared Global Objects can also create some circular referencing situations since submodules
  of the Shared Global Object can reference modules that reference itself (see
  [this MR for an example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/33366)).

Here are some historic examples where this pattern was identified to be problematic:

- [Reference to global Vuex store in IDE](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36401)
- [Docs update to discourage singleton Vuex store](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36952)

### When could the Shared Global Object pattern be actually appropriate?

Shared Global Object's solve the problem of making something globally accessible. This pattern
could be appropriate:

- When a responsibility is truly global and should be referenced across the application
  (e.g., an application-wide Event Bus).

Even in these scenarios, please consider avoiding the Shared Global Object pattern because the
side-effects can be notoriously difficult to reason with.

### References

To read more on this topic, check out the following references:

- [GlobalVariablesAreBad from C2 wiki](https://wiki.c2.com/?GlobalVariablesAreBad)

## Singleton (Anti-pattern)

The classic [Singleton pattern](https://en.wikipedia.org/wiki/Singleton_pattern) is an approach to ensure that only one
instance of a thing exists.

Here's an example of this pattern:

```javascript
class MyThing {
  constructor() {
    // ...
  }

  // ...
}

MyThing.instance = null;

export const getThingInstance = () => {
  if (MyThing.instance) {
    return MyThing.instance;
  }

  const instance = new MyThing();
  MyThing.instance = instance;
  return instance;
};
```

### What problems do Singletons cause?

It is a big assumption that only one instance of a thing should exist. More often than not,
a Singleton is misused and causes very tight coupling amongst itself and the modules that reference it.

Here are some historic examples where this pattern was identified to be problematic:

- [Test issues caused by singleton class in IDE](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/30398#note_331174190)
- [Implicit Singleton created by module's shared variables](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/97#note_417515776)
- [Complexity caused by Singletons](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/29461#note_324585814)

Here are some ills that Singletons often produce:

1. **Non-deterministic tests.** Singletons encourage non-deterministic tests because the single instance is shared across
   individual tests, often causing the state of one test to bleed into another.
1. **High coupling.** Under the hood, clients of a singleton class all share a single specific
   instance of an object, which means this pattern inherits all the [problems of Shared Global Object](#what-problems-do-shared-global-objects-cause)
   such as no clear ownership and no access control. These leads to high coupling situations that can
   be buggy and difficult to untangle.
1. **Infectious.** Singletons are infectious, especially when they manage state. Consider the component
   [RepoEditor](https://gitlab.com/gitlab-org/gitlab/-/blob/27ad6cb7b76430fbcbaf850df68c338d6719ed2b/app%2Fassets%2Fjavascripts%2Fide%2Fcomponents%2Frepo_editor.vue#L0-1)
   used in the Web IDE. This component interfaces with a Singleton [Editor](https://gitlab.com/gitlab-org/gitlab/-/blob/862ad57c44ec758ef3942ac2e7a2bd40a37a9c59/app%2Fassets%2Fjavascripts%2Fide%2Flib%2Feditor.js#L21)
   which manages some state for working with Monaco. Because of the Singleton nature of the Editor class,
   the component `RepoEditor` is now forced to be a Singleton as well. Multiple instances of this component
   would cause production issues because no one truly owns the instance of `Editor`.

### Why is the Singleton pattern popular in other languages like Java?

This is because of the limitations of languages like Java where everything has to be wrapped
in a class. In JavaScript we have things like object and function literals where we can solve
many problems with a module that exports utility functions.

### When could the Singleton pattern be actually appropriate?**

Singletons solve the problem of enforcing there to be only 1 instance of a thing. It's possible
that a Singleton could be appropriate in the following rare cases:

- We need to manage some resource that **MUST** have just 1 instance (i.e. some hardware restriction).
- There is a real [cross-cutting concern](https://en.wikipedia.org/wiki/Cross-cutting_concern) (e.g., logging) and a Singleton provides the simplest API.

Even in these scenarios, please consider avoiding the Singleton pattern.

### What alternatives are there to the Singleton pattern?

#### Utility Functions

When no state needs to be managed, we can simply export utility functions from a module without
messing with any class instantiation.

```javascript
// bad - Singleton
export class ThingUtils {
  static create() {
    if(this.instance) {
      return this.instance;
    }

    this.instance = new ThingUtils();
    return this.instance;
  }

  bar() { /* ... */ }

  fuzzify(id) { /* ... */ }
}

// good - Utility functions
export const bar = () => { /* ... */ };

export const fuzzify = (id) => { /* ... */ };
```

#### Dependency Injection

[Dependency Injection](https://en.wikipedia.org/wiki/Dependency_injection) is an approach which breaks
coupling by declaring a module's dependencies to be injected from outside the module (e.g., through constructor parameters, a bona-fide Dependency Injection framework, and even Vue's `provide/inject`).

```javascript
// bad - Vue component coupled to Singleton
export default {
  created() {
    this.mediator = MyFooMediator.getInstance();
  },
};

// good - Vue component declares dependency
export default {
  inject: ['mediator']
};
```

```javascript
// bad - We're not sure where the singleton is in it's lifecycle so we init it here.
export class Foo {
  constructor() {
    Bar.getInstance().init();
  }

  stuff() {
    return Bar.getInstance().doStuff();
  }
}

// good - Lets receive this dependency as a constructor argument.
// It's also not our responsibility to manage the lifecycle.
export class Foo {
  constructor(bar) {
    this.bar = bar;
  }

  stuff() {
    return this.bar.doStuff();
  }
}
```

In this example, the lifecycle and implementation details of `mediator` are all managed
**outside** the component (most likely the page entrypoint).
