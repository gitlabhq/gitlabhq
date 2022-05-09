import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StatusBox from '~/issuable/components/status_box.vue';

let wrapper;

function factory(propsData) {
  wrapper = shallowMount(StatusBox, {
    propsData,
    stubs: { GlSprintf },
    provide: { glFeatures: { updatedMrHeader: true } },
  });
}

const testCases = [
  {
    name: 'Open',
    state: 'opened',
    class: 'badge-success',
  },
  {
    name: 'Open',
    state: 'locked',
    class: 'badge-success',
  },
  {
    name: 'Closed',
    state: 'closed',
    class: 'badge-danger',
  },
  {
    name: 'Merged',
    state: 'merged',
    class: 'badge-info',
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
          issuableType: 'merge_request',
        });

        expect(wrapper.text()).toContain(testCase.name);
      });

      it('sets css class', () => {
        factory({
          initialState: testCase.state,
          issuableType: 'merge_request',
        });

        expect(wrapper.classes()).toContain(testCase.class);
      });
    });
  });
});
