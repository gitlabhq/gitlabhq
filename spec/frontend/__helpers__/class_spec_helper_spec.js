/* global ClassSpecHelper */

import './class_spec_helper';

describe('ClassSpecHelper', () => {
  let testContext;

  beforeEach(() => {
    testContext = {};
  });

  describe('itShouldBeAStaticMethod', () => {
    beforeEach(() => {
      class TestClass {
        instanceMethod() {
          this.prop = 'val';
        }
        static staticMethod() {}
      }

      testContext.TestClass = TestClass;
    });

    ClassSpecHelper.itShouldBeAStaticMethod(ClassSpecHelper, 'itShouldBeAStaticMethod');
  });
});
