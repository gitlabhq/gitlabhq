import { shallowMount } from '@vue/test-utils';
import DiffLine from '~/diffs/components/diff_line.vue';
import DiffCodeQuality from '~/diffs/components/diff_code_quality.vue';

const EXAMPLE_LINE_NUMBER = 3;
const EXAMPLE_DESCRIPTION = 'example description';
const EXAMPLE_SEVERITY = 'example severity';

const left = {
  line: {
    left: {
      codequality: [
        {
          line: EXAMPLE_LINE_NUMBER,
          description: EXAMPLE_DESCRIPTION,
          severity: EXAMPLE_SEVERITY,
        },
      ],
    },
  },
};

const right = {
  line: {
    right: {
      codequality: [
        {
          line: EXAMPLE_LINE_NUMBER,
          description: EXAMPLE_DESCRIPTION,
          severity: EXAMPLE_SEVERITY,
        },
      ],
    },
  },
};

const mockData = [right, left];

describe('DiffLine', () => {
  const createWrapper = (propsData) => {
    return shallowMount(DiffLine, { propsData });
  };

  it('should emit event when hideCodeQualityFindings is called', () => {
    const wrapper = createWrapper(right);

    wrapper.findComponent(DiffCodeQuality).vm.$emit('hideCodeQualityFindings');
    expect(wrapper.emitted()).toEqual({
      hideCodeQualityFindings: [[EXAMPLE_LINE_NUMBER]],
    });
  });

  mockData.forEach((element) => {
    it('should set correct props for DiffCodeQuality', () => {
      const wrapper = createWrapper(element);
      expect(wrapper.findComponent(DiffCodeQuality).props('codeQuality')).toEqual([
        {
          line: EXAMPLE_LINE_NUMBER,
          description: EXAMPLE_DESCRIPTION,
          severity: EXAMPLE_SEVERITY,
        },
      ]);
    });
  });
});
