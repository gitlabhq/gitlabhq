import { mountExtended } from 'helpers/vue_test_utils_helper';

import RunnerTag from '~/ci/runner/components/runner_tag.vue';
import RunnerTags from '~/ci/runner/components/runner_tags.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('RunnerTags', () => {
  let wrapper;

  const findTags = () => wrapper.findAllComponents(RunnerTag);
  const findTagAt = (i = 0) => findTags().at(i);
  const findButton = () => wrapper.find('button');
  const getButtonTooltip = () => getBinding(findButton().element, 'gl-tooltip').value;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = mountExtended(RunnerTags, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        tagList: ['tag1', 'tag2', 'tag3'],
        ...props,
      },
    });
  };

  describe.each`
    case                                         | limit
    ${'with no limit'}                           | ${undefined}
    ${'with limit that would hide a single tag'} | ${2}
  `('$case', ({ limit }) => {
    beforeEach(() => {
      createComponent({
        props: { limit },
      });
    });

    it('Displays all tags', () => {
      expect(wrapper.text()).toMatchInterpolatedText('tag1 tag2 tag3');

      expect(findTags()).toHaveLength(3);

      expect(findTagAt(0).props('tag')).toBe('tag1');
      expect(findTagAt(1).props('tag')).toBe('tag2');
      expect(findTagAt(2).props('tag')).toBe('tag3');
    });
  });

  describe('with limit', () => {
    beforeEach(() => {
      createComponent({
        props: { limit: 1 },
      });
    });

    it('Displays limited tags', () => {
      expect(wrapper.text()).toMatchInterpolatedText('tag1 +2 more');

      expect(findTags()).toHaveLength(1);
      expect(findTagAt(0).props('tag')).toBe('tag1');

      expect(findButton().text()).toBe('+2 more');
      expect(getButtonTooltip()).toEqual('Show 2 more tags');
    });

    it('when expanding collapsed tags, shows all tags', async () => {
      await findButton().trigger('click');

      expect(wrapper.text()).toMatchInterpolatedText('tag1 tag2 tag3');

      expect(findTags()).toHaveLength(3);
      expect(findTagAt(0).props('tag')).toBe('tag1');
      expect(findTagAt(1).props('tag')).toBe('tag2');
      expect(findTagAt(2).props('tag')).toBe('tag3');

      expect(findButton().exists()).toBe(false);
    });
  });

  it('Is empty when there are no tags', () => {
    createComponent({
      props: { tagList: null },
    });

    expect(wrapper.text()).toBe('');
    expect(findTags()).toHaveLength(0);
  });
});
