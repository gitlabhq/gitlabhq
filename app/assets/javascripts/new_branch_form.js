/* eslint-disable func-names, no-return-assign, @gitlab/require-i18n-strings */
export default class NewBranchForm {
  constructor(form) {
    this.validate = this.validate.bind(this);
    this.branchNameError = form.querySelector('.js-branch-name-error');
    this.name = form.querySelector('.js-branch-name');
    this.setupRestrictions();
    this.addBinding();
    this.init();
  }

  addBinding() {
    this.name.addEventListener('change', this.validate);
  }

  init() {
    if (this.name != null && this.name.value.length > 0) {
      const event = new CustomEvent('change');
      this.name.dispatchEvent(event);
    }
  }

  setupRestrictions() {
    const startsWith = {
      pattern: /^(\/|\.)/g,
      prefix: "can't start with",
      conjunction: 'or',
    };
    const endsWith = {
      pattern: /(\/|\.|\.lock)$/g,
      prefix: "can't end in",
      conjunction: 'or',
    };
    const invalid = {
      pattern: /(\s|~|\^|:|\?|\*|\[|\\|\.\.|@\{|\/{2,}){1}/g,
      prefix: "can't contain",
      conjunction: ', ',
    };
    const single = {
      pattern: /^@+$/g,
      prefix: "can't be",
      conjunction: 'or',
    };
    return (this.restrictions = [startsWith, invalid, endsWith, single]);
  }

  validate() {
    const { indexOf } = [];

    this.branchNameError.innerHTML = '';
    const unique = function (values, value) {
      if (indexOf.call(values, value) === -1) {
        values.push(value);
      }
      return values;
    };
    const formatter = function (values, restriction) {
      const formatted = values.map((value) => {
        switch (false) {
          case !/\s/.test(value):
            return 'spaces';
          case !/\/{2,}/g.test(value):
            return 'consecutive slashes';
          default:
            return `'${value}'`;
        }
      });
      return `${restriction.prefix} ${formatted.join(restriction.conjunction)}`;
    };
    const validator = (errors, restriction) => {
      const matched = this.name.value.match(restriction.pattern);
      if (matched) {
        return errors.concat(formatter(matched.reduce(unique, []), restriction));
      }
      return errors;
    };
    const errors = this.restrictions.reduce(validator, []);
    if (errors.length > 0) {
      this.branchNameError.textContent = errors.join(', ');
      this.name.focus();
    }
  }
}
