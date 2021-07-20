import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerTag from '~/runner/components/runner_tag.vue';

describe('RunnerTag', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(RunnerTag, {
      propsData: {
        tag: 'tag1',
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays tag text', () => {
    expect(wrapper.text()).toBe('tag1');
  });

  it('Displays tags with correct style', () => {
    expect(findBadge().props()).toMatchObject({
      size: 'md',
      variant: 'info',
    });
  });

  it('Displays tags with small size', () => {
    createComponent({
      props: { size: 'sm' },
    });

    expect(findBadge().props('size')).toBe('sm');
  });
});
