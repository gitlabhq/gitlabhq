import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TitleField from '~/issues/show/components/fields/title.vue';
import eventHub from '~/issues/show/event_hub';

describe('Title field component', () => {
  let wrapper;

  const findInput = () => wrapper.findComponent(GlFormInput);

  beforeEach(() => {
    jest.spyOn(eventHub, '$emit');

    wrapper = shallowMount(TitleField, {
      propsData: {
        value: 'test',
      },
      stubs: {
        GlFormGroup,
        GlFormInput,
      },
    });
  });

  it('renders form control with formState title', () => {
    expect(findInput().props('value')).toBe('test');
  });

  it('triggers update with meta+enter', () => {
    findInput().trigger('keydown.enter', { metaKey: true });

    expect(eventHub.$emit).toHaveBeenCalledWith('update.issuable');
  });

  it('triggers update with ctrl+enter', () => {
    findInput().trigger('keydown.enter', { ctrlKey: true });

    expect(eventHub.$emit).toHaveBeenCalledWith('update.issuable');
  });
});
