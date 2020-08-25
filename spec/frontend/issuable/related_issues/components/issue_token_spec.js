import Vue from 'vue';
import { PathIdSeparator } from '~/related_issues/constants';
import issueToken from '~/related_issues/components/issue_token.vue';

describe('IssueToken', () => {
  const idKey = 200;
  const displayReference = 'foo/bar#123';
  const title = 'some title';
  const pathIdSeparator = PathIdSeparator.Issue;
  const eventNamespace = 'pendingIssuable';
  let IssueToken;
  let vm;

  beforeEach(() => {
    IssueToken = Vue.extend(issueToken);
  });

  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('with reference supplied', () => {
    beforeEach(() => {
      vm = new IssueToken({
        propsData: {
          idKey,
          eventNamespace,
          displayReference,
          pathIdSeparator,
        },
      }).$mount();
    });

    it('shows reference', () => {
      expect(vm.$el.textContent.trim()).toEqual(displayReference);
    });

    it('does not link without path specified', () => {
      expect(vm.$refs.link.tagName.toLowerCase()).toEqual('span');
      expect(vm.$refs.link.getAttribute('href')).toBeNull();
    });
  });

  describe('with reference and title supplied', () => {
    beforeEach(() => {
      vm = new IssueToken({
        propsData: {
          idKey,
          eventNamespace,
          displayReference,
          pathIdSeparator,
          title,
        },
      }).$mount();
    });

    it('shows reference and title', () => {
      expect(vm.$refs.reference.textContent.trim()).toEqual(displayReference);
      expect(vm.$refs.title.textContent.trim()).toEqual(title);
    });
  });

  describe('with path supplied', () => {
    const path = '/foo/bar/issues/123';
    beforeEach(() => {
      vm = new IssueToken({
        propsData: {
          idKey,
          eventNamespace,
          displayReference,
          pathIdSeparator,
          title,
          path,
        },
      }).$mount();
    });

    it('links reference and title', () => {
      expect(vm.$refs.link.getAttribute('href')).toEqual(path);
    });
  });

  describe('with state supplied', () => {
    describe("`state: 'opened'`", () => {
      beforeEach(() => {
        vm = new IssueToken({
          propsData: {
            idKey,
            eventNamespace,
            displayReference,
            pathIdSeparator,
            state: 'opened',
          },
        }).$mount();
      });

      it('shows green circle icon', () => {
        expect(vm.$el.querySelector('.issue-token-state-icon-open.fa.fa-circle-o')).toBeDefined();
      });
    });

    describe("`state: 'reopened'`", () => {
      beforeEach(() => {
        vm = new IssueToken({
          propsData: {
            idKey,
            eventNamespace,
            displayReference,
            pathIdSeparator,
            state: 'reopened',
          },
        }).$mount();
      });

      it('shows green circle icon', () => {
        expect(vm.$el.querySelector('.issue-token-state-icon-open.fa.fa-circle-o')).toBeDefined();
      });
    });

    describe("`state: 'closed'`", () => {
      beforeEach(() => {
        vm = new IssueToken({
          propsData: {
            idKey,
            eventNamespace,
            displayReference,
            pathIdSeparator,
            state: 'closed',
          },
        }).$mount();
      });

      it('shows red minus icon', () => {
        expect(vm.$el.querySelector('.issue-token-state-icon-closed.fa.fa-minus')).toBeDefined();
      });
    });
  });

  describe('with reference, title, state', () => {
    const state = 'opened';
    beforeEach(() => {
      vm = new IssueToken({
        propsData: {
          idKey,
          eventNamespace,
          displayReference,
          pathIdSeparator,
          title,
          state,
        },
      }).$mount();
    });

    it('shows reference, title, and state', () => {
      const stateIcon = vm.$refs.reference.querySelector('svg');

      expect(stateIcon.getAttribute('aria-label')).toEqual(state);
      expect(vm.$refs.reference.textContent.trim()).toEqual(displayReference);
      expect(vm.$refs.title.textContent.trim()).toEqual(title);
    });
  });

  describe('with canRemove', () => {
    describe('`canRemove: false` (default)', () => {
      beforeEach(() => {
        vm = new IssueToken({
          propsData: {
            idKey,
            eventNamespace,
            displayReference,
            pathIdSeparator,
          },
        }).$mount();
      });

      it('does not have remove button', () => {
        expect(vm.$el.querySelector('.issue-token-remove-button')).toBeNull();
      });
    });

    describe('`canRemove: true`', () => {
      beforeEach(() => {
        vm = new IssueToken({
          propsData: {
            idKey,
            eventNamespace,
            displayReference,
            pathIdSeparator,
            canRemove: true,
          },
        }).$mount();
      });

      it('has remove button', () => {
        expect(vm.$el.querySelector('.issue-token-remove-button')).toBeDefined();
      });
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      vm = new IssueToken({
        propsData: {
          idKey,
          eventNamespace,
          displayReference,
          pathIdSeparator,
        },
      }).$mount();
    });

    it('when getting checked', () => {
      jest.spyOn(vm, '$emit').mockImplementation(() => {});
      vm.onRemoveRequest();

      expect(vm.$emit).toHaveBeenCalledWith('pendingIssuableRemoveRequest', vm.idKey);
    });
  });

  describe('tooltip', () => {
    beforeEach(() => {
      vm = new IssueToken({
        propsData: {
          idKey,
          eventNamespace,
          displayReference,
          pathIdSeparator,
          canRemove: true,
        },
      }).$mount();
    });

    it('should not be escaped', () => {
      const { originalTitle } = vm.$refs.removeButton.dataset;

      expect(originalTitle).toEqual(`Remove ${displayReference}`);
    });
  });
});
