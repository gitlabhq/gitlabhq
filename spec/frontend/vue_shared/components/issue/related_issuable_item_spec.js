import Vue from 'vue';
import { mount } from '@vue/test-utils';
import { formatDate } from '~/lib/utils/datetime_utility';
import RelatedIssuableItem from '~/vue_shared/components/issue/related_issuable_item.vue';
import {
  defaultAssignees,
  defaultMilestone,
} from '../../../../javascripts/vue_shared/components/issue/related_issuable_mock_data';

describe('RelatedIssuableItem', () => {
  let wrapper;
  const props = {
    idKey: 1,
    displayReference: 'gitlab-org/gitlab-test#1',
    pathIdSeparator: '#',
    path: `${gl.TEST_HOST}/path`,
    title: 'title',
    confidential: true,
    dueDate: '1990-12-31',
    weight: 10,
    createdAt: '2018-12-01T00:00:00.00Z',
    milestone: defaultMilestone,
    assignees: defaultAssignees,
    eventNamespace: 'relatedIssue',
  };
  const slots = {
    dueDate: '<div class="js-due-date-slot"></div>',
    weight: '<div class="js-weight-slot"></div>',
  };

  beforeEach(() => {
    wrapper = mount(RelatedIssuableItem, {
      slots,
      attachToDocument: true,
      propsData: props,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('contains issuable-info-container class when canReorder is false', () => {
    expect(wrapper.props('canReorder')).toBe(false);
    expect(wrapper.find('.issuable-info-container').exists()).toBe(true);
  });

  it('does not render token state', () => {
    expect(wrapper.find('.text-secondary svg').exists()).toBe(false);
  });

  it('does not render remove button', () => {
    expect(wrapper.find({ ref: 'removeButton' }).exists()).toBe(false);
  });

  describe('token title', () => {
    it('links to computedPath', () => {
      expect(wrapper.find('.item-title a').attributes('href')).toEqual(wrapper.props('path'));
    });

    it('renders confidential icon', () => {
      expect(wrapper.find('.confidential-icon').exists()).toBe(true);
    });

    it('renders title', () => {
      expect(wrapper.find('.item-title a').text()).toEqual(props.title);
    });
  });

  describe('token state', () => {
    let tokenState;

    beforeEach(done => {
      wrapper.setProps({ state: 'opened' });

      Vue.nextTick(() => {
        tokenState = wrapper.find('.issue-token-state-icon-open');

        done();
      });
    });

    it('renders if hasState', () => {
      expect(tokenState.exists()).toBe(true);
    });

    it('renders state title', () => {
      const stateTitle = tokenState.attributes('title');
      const formattedCreateDate = formatDate(props.createdAt);

      expect(stateTitle).toContain('<span class="bold">Opened</span>');

      expect(stateTitle).toContain(`<span class="text-tertiary">${formattedCreateDate}</span>`);
    });

    it('renders aria label', () => {
      expect(tokenState.attributes('aria-label')).toEqual('opened');
    });

    it('renders open icon when open state', () => {
      expect(tokenState.classes('issue-token-state-icon-open')).toBe(true);
    });

    it('renders close icon when close state', done => {
      wrapper.setProps({
        state: 'closed',
        closedAt: '2018-12-01T00:00:00.00Z',
      });

      Vue.nextTick(() => {
        expect(tokenState.classes('issue-token-state-icon-closed')).toBe(true);

        done();
      });
    });
  });

  describe('token metadata', () => {
    let tokenMetadata;

    beforeEach(done => {
      Vue.nextTick(() => {
        tokenMetadata = wrapper.find('.item-meta');

        done();
      });
    });

    it('renders item path and ID', () => {
      const pathAndID = tokenMetadata.find('.item-path-id').text();

      expect(pathAndID).toContain('gitlab-org/gitlab-test');
      expect(pathAndID).toContain('#1');
    });

    it('renders milestone icon and name', () => {
      const milestoneIcon = tokenMetadata.find('.item-milestone svg use');
      const milestoneTitle = tokenMetadata.find('.item-milestone .milestone-title');

      expect(milestoneIcon.attributes('href')).toContain('clock');
      expect(milestoneTitle.text()).toContain('Milestone title');
    });

    it('renders due date component', () => {
      expect(tokenMetadata.find('.js-due-date-slot').exists()).toBe(true);
    });

    it('renders weight component', () => {
      expect(tokenMetadata.find('.js-weight-slot').exists()).toBe(true);
    });
  });

  describe('token assignees', () => {
    it('renders assignees avatars', () => {
      // Expect 2 times 2 because assignees are rendered twice, due to layout issues
      expect(wrapper.findAll('.item-assignees .user-avatar-link').length).toBeDefined();

      expect(wrapper.find('.item-assignees .avatar-counter').text()).toContain('+2');
    });
  });

  describe('remove button', () => {
    let removeBtn;

    beforeEach(done => {
      wrapper.setProps({ canRemove: true });
      Vue.nextTick(() => {
        removeBtn = wrapper.find({ ref: 'removeButton' });

        done();
      });
    });

    it('renders if canRemove', () => {
      expect(removeBtn.exists()).toBe(true);
    });

    it('renders disabled button when removeDisabled', done => {
      wrapper.vm.removeDisabled = true;

      Vue.nextTick(() => {
        expect(removeBtn.attributes('disabled')).toEqual('disabled');

        done();
      });
    });

    it('triggers onRemoveRequest when clicked', () => {
      removeBtn.trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        const { relatedIssueRemoveRequest } = wrapper.emitted();

        expect(relatedIssueRemoveRequest.length).toBe(1);
        expect(relatedIssueRemoveRequest[0]).toEqual([props.idKey]);
      });
    });
  });
});
