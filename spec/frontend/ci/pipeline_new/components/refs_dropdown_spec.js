import { shallowMount } from '@vue/test-utils';

import RefSelector from '~/ref/components/ref_selector.vue';
import RefsDropdown from '~/ci/pipeline_new/components/refs_dropdown.vue';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';

const projectId = '8';
const refShortName = 'main';
const refFullName = 'refs/heads/main';

describe('Pipeline New Form', () => {
  let wrapper;

  const findRefSelector = () => wrapper.findComponent(RefSelector);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(RefsDropdown, {
      propsData: {
        projectId,
        value: {
          shortName: refShortName,
          fullName: refFullName,
        },
        ...props,
      },
    });
  };

  describe('when user opens dropdown', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has default selected branch', () => {
      expect(findRefSelector().props('value')).toBe('main');
    });

    it('has ref selector for branches and tags', () => {
      expect(findRefSelector().props('enabledRefTypes')).toEqual([
        REF_TYPE_BRANCHES,
        REF_TYPE_TAGS,
      ]);
    });

    describe('when user selects a value', () => {
      const fullName = `refs/heads/conflict-contains-conflict-markers`;

      it('component emits @input', () => {
        findRefSelector().vm.$emit('input', fullName);

        const inputs = wrapper.emitted('input');

        expect(inputs).toHaveLength(1);
        expect(inputs[0]).toEqual([
          {
            shortName: 'conflict-contains-conflict-markers',
            fullName: 'refs/heads/conflict-contains-conflict-markers',
          },
        ]);
      });
    });
  });

  describe('when user has selected a value', () => {
    const mockShortName = 'conflict-contains-conflict-markers';
    const mockFullName = `refs/heads/${mockShortName}`;

    it('branch is checked', () => {
      createComponent({
        value: {
          shortName: mockShortName,
          fullName: mockFullName,
        },
      });

      expect(findRefSelector().props('value')).toBe(mockShortName);
    });
  });
});
