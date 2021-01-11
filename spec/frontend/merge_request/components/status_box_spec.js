import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import StatusBox from '~/merge_request/components/status_box.vue';
import mrEventHub from '~/merge_request/eventhub';

let wrapper;

function factory(propsData) {
  wrapper = shallowMount(StatusBox, { propsData, stubs: { GlSprintf } });
}

const testCases = [
  {
    name: 'Open',
    state: 'opened',
    class: 'status-box-open',
    icon: 'issue-open-m',
  },
  {
    name: 'Closed',
    state: 'closed',
    class: 'status-box-mr-closed',
    icon: 'close',
  },
  {
    name: 'Merged',
    state: 'merged',
    class: 'status-box-mr-merged',
    icon: 'git-merge',
  },
];

describe('Merge request status box component', () => {
  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  testCases.forEach((testCase) => {
    describe(`when merge request is ${testCase.name}`, () => {
      it('renders human readable test', () => {
        factory({
          initialState: testCase.state,
          initialIsReverted: false,
        });

        expect(wrapper.text()).toContain(testCase.name);
      });

      it('sets css class', () => {
        factory({
          initialState: testCase.state,
          initialIsReverted: false,
        });

        expect(wrapper.classes()).toContain(testCase.class);
      });

      it('renders icon', () => {
        factory({
          initialState: testCase.state,
          initialIsReverted: false,
        });

        expect(wrapper.find('[data-testid="status-icon"]').props('name')).toBe(testCase.icon);
      });
    });
  });

  describe('when merge request is reverted', () => {
    it('renders a link to the reverted merge request', () => {
      factory({
        initialState: 'merged',
        initialIsReverted: true,
        initialRevertedPath: 'http://test.com',
      });

      expect(wrapper.find('[data-testid="reverted-link"]').attributes('href')).toBe(
        'http://test.com',
      );
    });
  });

  it('updates with eventhub event', async () => {
    factory({
      initialState: 'opened',
      initialIsReverted: false,
    });

    expect(wrapper.text()).toContain('Open');

    mrEventHub.$emit('mr.state.updated', { state: 'closed', reverted: false });

    await nextTick();

    expect(wrapper.text()).toContain('Closed');
  });
});
