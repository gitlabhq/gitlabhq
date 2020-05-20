// eslint-disable-next-line jest/no-export
export default class ClassSpecHelper {
  static itShouldBeAStaticMethod(base, method) {
    return it('should be a static method', () => {
      expect(Object.prototype.hasOwnProperty.call(base, method)).toBeTruthy();
    });
  }
}

window.ClassSpecHelper = ClassSpecHelper;
