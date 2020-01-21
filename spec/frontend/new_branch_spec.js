import $ from 'jquery';
import NewBranchForm from '~/new_branch_form';

describe('Branch', () => {
  let testContext;

  beforeEach(() => {
    testContext = {};
  });

  describe('create a new branch', () => {
    preloadFixtures('branches/new_branch.html');

    function fillNameWith(value) {
      $('.js-branch-name')
        .val(value)
        .trigger('blur');
    }

    function expectToHaveError(error) {
      expect($('.js-branch-name-error span').text()).toEqual(error);
    }

    beforeEach(() => {
      loadFixtures('branches/new_branch.html');
      $('form').on('submit', e => e.preventDefault());
      testContext.form = new NewBranchForm($('.js-create-branch-form'), []);
    });

    it("can't start with a dot", () => {
      fillNameWith('.foo');
      expectToHaveError("can't start with '.'");
    });

    it("can't start with a slash", () => {
      fillNameWith('/foo');
      expectToHaveError("can't start with '/'");
    });

    it("can't have two consecutive dots", () => {
      fillNameWith('foo..bar');
      expectToHaveError("can't contain '..'");
    });

    it("can't have spaces anywhere", () => {
      fillNameWith(' foo');
      expectToHaveError("can't contain spaces");
      fillNameWith('foo bar');
      expectToHaveError("can't contain spaces");
      fillNameWith('foo ');
      expectToHaveError("can't contain spaces");
    });

    it("can't have ~ anywhere", () => {
      fillNameWith('~foo');
      expectToHaveError("can't contain '~'");
      fillNameWith('foo~bar');
      expectToHaveError("can't contain '~'");
      fillNameWith('foo~');
      expectToHaveError("can't contain '~'");
    });

    it("can't have tilde anwhere", () => {
      fillNameWith('~foo');
      expectToHaveError("can't contain '~'");
      fillNameWith('foo~bar');
      expectToHaveError("can't contain '~'");
      fillNameWith('foo~');
      expectToHaveError("can't contain '~'");
    });

    it("can't have caret anywhere", () => {
      fillNameWith('^foo');
      expectToHaveError("can't contain '^'");
      fillNameWith('foo^bar');
      expectToHaveError("can't contain '^'");
      fillNameWith('foo^');
      expectToHaveError("can't contain '^'");
    });

    it("can't have : anywhere", () => {
      fillNameWith(':foo');
      expectToHaveError("can't contain ':'");
      fillNameWith('foo:bar');
      expectToHaveError("can't contain ':'");
      fillNameWith(':foo');
      expectToHaveError("can't contain ':'");
    });

    it("can't have question mark anywhere", () => {
      fillNameWith('?foo');
      expectToHaveError("can't contain '?'");
      fillNameWith('foo?bar');
      expectToHaveError("can't contain '?'");
      fillNameWith('foo?');
      expectToHaveError("can't contain '?'");
    });

    it("can't have asterisk anywhere", () => {
      fillNameWith('*foo');
      expectToHaveError("can't contain '*'");
      fillNameWith('foo*bar');
      expectToHaveError("can't contain '*'");
      fillNameWith('foo*');
      expectToHaveError("can't contain '*'");
    });

    it("can't have open bracket anywhere", () => {
      fillNameWith('[foo');
      expectToHaveError("can't contain '['");
      fillNameWith('foo[bar');
      expectToHaveError("can't contain '['");
      fillNameWith('foo[');
      expectToHaveError("can't contain '['");
    });

    it("can't have a backslash anywhere", () => {
      fillNameWith('\\foo');
      expectToHaveError("can't contain '\\'");
      fillNameWith('foo\\bar');
      expectToHaveError("can't contain '\\'");
      fillNameWith('foo\\');
      expectToHaveError("can't contain '\\'");
    });

    it("can't contain a sequence @{ anywhere", () => {
      fillNameWith('@{foo');
      expectToHaveError("can't contain '@{'");
      fillNameWith('foo@{bar');
      expectToHaveError("can't contain '@{'");
      fillNameWith('foo@{');
      expectToHaveError("can't contain '@{'");
    });

    it("can't have consecutive slashes", () => {
      fillNameWith('foo//bar');
      expectToHaveError("can't contain consecutive slashes");
    });

    it("can't end with a slash", () => {
      fillNameWith('foo/');
      expectToHaveError("can't end in '/'");
    });

    it("can't end with a dot", () => {
      fillNameWith('foo.');
      expectToHaveError("can't end in '.'");
    });

    it("can't end with .lock", () => {
      fillNameWith('foo.lock');
      expectToHaveError("can't end in '.lock'");
    });

    it("can't be the single character @", () => {
      fillNameWith('@');
      expectToHaveError("can't be '@'");
    });

    it('concatenates all error messages', () => {
      fillNameWith('/foo bar?~.');
      expectToHaveError("can't start with '/', can't contain spaces, '?', '~', can't end in '.'");
    });

    it("doesn't duplicate error messages", () => {
      fillNameWith('?foo?bar?zoo?');
      expectToHaveError("can't contain '?'");
    });

    it('removes the error message when is a valid name', () => {
      fillNameWith('foo?bar');

      expect($('.js-branch-name-error span').length).toEqual(1);
      fillNameWith('foobar');

      expect($('.js-branch-name-error span').length).toEqual(0);
    });

    it('can have dashes anywhere', () => {
      fillNameWith('-foo-bar-zoo-');

      expect($('.js-branch-name-error span').length).toEqual(0);
    });

    it('can have underscores anywhere', () => {
      fillNameWith('_foo_bar_zoo_');

      expect($('.js-branch-name-error span').length).toEqual(0);
    });

    it('can have numbers anywhere', () => {
      fillNameWith('1foo2bar3zoo4');

      expect($('.js-branch-name-error span').length).toEqual(0);
    });

    it('can be only letters', () => {
      fillNameWith('foo');

      expect($('.js-branch-name-error span').length).toEqual(0);
    });
  });
});
