// THIS IS AN EXAMPLE
//
// This file contains a basic documented example of the Source Editor extensions'
// API for your convenience. You can copy/paste it into your own file
// and adjust as you see fit
//

export class MyFancyExtension {
  /**
   * A required getter returning the extension's name
   * We have to provide it for every extension instead of relying on the built-in
   * `name` prop because the prop does not survive the webpack's minification
   * and the name mangling.
   * @returns {string}
   */
  static get extensionName() {
    return 'MyFancyExtension';
  }
  /**
   * THE LIFE-CYCLE CALLBACKS
   */

  /**
   * Is called before the extension gets used by an instance,
   * Use `onSetup` to setup Monaco directly:
   * actions, keystrokes, update options, etc.
   * Is called only once before the extension gets registered
   *
   * @param { Object } [instance] The Source Editor instance
   * @param { Object } [setupOptions]  The setupOptions object
   */
  // eslint-disable-next-line class-methods-use-this,no-unused-vars
  onSetup(instance, setupOptions) {}

  /**
   * The first thing called after the extension is
   * registered and used by an instance.
   * Is called every time the extension is applied
   *
   * @param { Object } [instance] The Source Editor instance
   */
  // eslint-disable-next-line class-methods-use-this,no-unused-vars
  onUse(instance) {}

  /**
   * Is called before un-using an extension. Can be used for time-critical
   * actions like cleanup, reverting visual changes, and other user-facing
   * updates.
   *
   * @param { Object } [instance] The Source Editor instance
   */
  // eslint-disable-next-line class-methods-use-this,no-unused-vars
  onBeforeUnuse(instance) {}

  /**
   * Is called right after an extension is removed from an instance (un-used)
   * Can be used for non time-critical tasks like cleanup on the Monaco level
   * (removing actions, keystrokes, etc.).
   * onUnuse() will be executed during the browser's idle period
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window/requestIdleCallback)
   *
   * @param { Object } [instance] The Source Editor instance
   */
  // eslint-disable-next-line class-methods-use-this,no-unused-vars
  onUnuse(instance) {}

  /**
   * The public API of the extension: these are the methods that will be exposed
   * to the end user
   * @returns {Object}
   */
  provides() {
    return {
      basic: () => {
        // The most basic method not depending on anything
        // Use: instance.basic();
        // eslint-disable-next-line @gitlab/require-i18n-strings
        return 'Foo Bar';
      },
      basicWithProp: () => {
        // The methods with access to the props of the extension.
        // The props can be either hardcoded (for example in `onSetup`), or
        // can be dynamically passed as part of `setupOptions` object when
        // using the extension.
        // Use: instance.use({ definition: MyFancyExtension, setupOptions: { foo: 'bar' }});
        return this.foo;
      },
      basicWithPropsAsList: (prop1, prop2) => {
        // Just a simple method with local props
        // The props are passed as usually.
        // Use: instance.basicWithPropsAsList(prop1, prop2);
        // eslint-disable-next-line @gitlab/require-i18n-strings
        return `The prop1 is ${prop1}; the prop2 is ${prop2}`;
      },
      basicWithInstance: (instance) => {
        // The method accessing the instance methods: either own or provided
        // by previously-registered extensions
        // `instance` is always supplied to all methods in provides() as THE LAST
        // argument.
        // You don't need to explicitly pass instance to this method:
        // Use: instance.basicWithInstance();
        // eslint-disable-next-line @gitlab/require-i18n-strings
        return `We have access to the whole Instance! ${instance.alpha()}`;
      },
      // eslint-disable-next-line max-params
      advancedWithInstanceAndProps: ({ author, book } = {}, firstname, lastname, instance) => {
        // Advanced method where
        // { author, book } — are the props passed as an object
        // prop1, prop2    — are the props passed as simple list
        // instance        — is automatically supplied, no need to pass it to
        //                   the method explicitly
        // Use: instance.advancedWithInstanceAndProps(
        //     {
        //       author: 'Franz Kafka',
        //       book: 'The Transformation'
        //     },
        //     'Franz',
        //     'Kafka'
        //   );
        return `
The author is ${author}; the book is ${book}
The author's name is ${firstname}; the last name is ${lastname}
We have access to the whole Instance! For example, 'instance.alpha()': ${instance.alpha()}`;
      },
    };
  }
}
