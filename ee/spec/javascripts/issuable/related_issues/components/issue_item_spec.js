import Vue from 'vue';
import issueItem from 'ee/related_issues/components/issue_item.vue';
import eventHub from 'ee/related_issues/event_hub';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('issueItem', () => {
  let vm;
  const props = {
    idKey: 1,
    displayReference: '#1',
    path: `${gl.TEST_HOST}/path`,
    title: 'title',
  };

  beforeEach(() => {
    const IssueItem = Vue.extend(issueItem);
    vm = mountComponent(IssueItem, props);
  });

  it('contains issue-info-container class when canReorder is false', () => {
    expect(vm.canReorder).toEqual(false);
    expect(vm.$el.querySelector('.issue-info-container')).toBeNull();
  });

  it('renders displayReference', () => {
    expect(vm.$el.querySelector('.text-secondary').innerText.trim()).toEqual(props.displayReference);
  });

  it('does not render token state', () => {
    expect(vm.$el.querySelector('.text-secondary svg')).toBeNull();
  });

  it('does not render remove button', () => {
    expect(vm.$refs.removeButton).toBeUndefined();
  });

  describe('token title', () => {
    it('links to computedPath', () => {
      expect(vm.$el.querySelector('a').href).toEqual(props.path);
    });

    it('renders title', () => {
      expect(vm.$el.querySelector('a').innerText.trim()).toEqual(props.title);
    });
  });

  describe('token state', () => {
    let tokenState;

    beforeEach((done) => {
      vm.state = 'opened';
      Vue.nextTick(() => {
        tokenState = vm.$el.querySelector('.text-secondary svg');
        done();
      });
    });

    it('renders if hasState', () => {
      expect(tokenState).toBeDefined();
    });

    it('renders state title', () => {
      expect(tokenState.getAttribute('data-original-title')).toEqual('Open');
    });

    it('renders aria label', () => {
      expect(tokenState.getAttribute('aria-label')).toEqual('opened');
    });

    it('renders open icon when open state', () => {
      expect(tokenState.classList.contains('issue-token-state-icon-open')).toEqual(true);
    });

    it('renders close icon when close state', (done) => {
      vm.state = 'closed';

      Vue.nextTick(() => {
        expect(tokenState.classList.contains('issue-token-state-icon-closed')).toEqual(true);
        done();
      });
    });
  });

  describe('remove button', () => {
    let removeBtn;

    beforeEach((done) => {
      vm.canRemove = true;
      Vue.nextTick(() => {
        removeBtn = vm.$refs.removeButton;
        done();
      });
    });

    it('renders if canRemove', () => {
      expect(removeBtn).toBeDefined();
    });

    it('renders disabled button when removeDisabled', (done) => {
      vm.removeDisabled = true;
      Vue.nextTick(() => {
        expect(removeBtn.hasAttribute('disabled')).toEqual(true);
        done();
      });
    });

    it('triggers onRemoveRequest when clicked', () => {
      const spy = jasmine.createSpy('spy');
      eventHub.$on('removeRequest', spy);
      removeBtn.click();

      expect(spy).toHaveBeenCalled();
    });
  });
});
