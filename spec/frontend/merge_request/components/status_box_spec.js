import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
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
    name: 'Open',
    state: 'locked',
    class: 'status-box-open',
    icon: 'issue-open-m',
  },
  {
    name: 'Closed',
    state: 'closed',
    class: 'status-box-mr-closed',
    icon: 'issue-close',
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
        });

        expect(wrapper.text()).toContain(testCase.name);
      });

      it('sets css class', () => {
        factory({
          initialState: testCase.state,
        });

        expect(wrapper.classes()).toContain(testCase.class);
      });

      it('renders icon', () => {
        factory({
          initialState: testCase.state,
        });

        expect(wrapper.find('[data-testid="status-icon"]').props('name')).toBe(testCase.icon);
      });
    });
  });

  it('updates with eventhub event', async () => {
    factory({
      initialState: 'opened',
    });

    expect(wrapper.text()).toContain('Open');

    mrEventHub.$emit('mr.state.updated', { state: 'closed' });

    await nextTick();

    expect(wrapper.text()).toContain('Closed');
  });
});
