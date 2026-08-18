import { mount } from '@vue/test-utils';
import { getFirstComponentChild } from '~/lib/utils/vue3compat/get_first_component_child';

describe('getFirstComponentChild', () => {
  const Child = {
    name: 'ProbeChild',
    template: '<span>child</span>',
  };

  it('returns the first component instance rendered by the vm', () => {
    const wrapper = mount({
      components: { Child },
      template: '<div><p>text</p><child /></div>',
    });

    const child = getFirstComponentChild(wrapper.vm);
    expect(child).not.toBeNull();
    expect(child.$options.name ?? child.$.type.name).toBe('ProbeChild');
  });

  it('returns null when the vm renders no components', () => {
    const wrapper = mount({ template: '<div><p>text</p></div>' });

    expect(getFirstComponentChild(wrapper.vm)).toBeNull();
  });

  it('returns null for a missing vm', () => {
    expect(getFirstComponentChild(null)).toBeNull();
  });
});
