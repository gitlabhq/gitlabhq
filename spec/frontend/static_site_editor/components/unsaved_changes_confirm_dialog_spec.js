import { shallowMount } from '@vue/test-utils';

import UnsavedChangesConfirmDialog from '~/static_site_editor/components/unsaved_changes_confirm_dialog.vue';

describe('static_site_editor/components/unsaved_changes_confirm_dialog', () => {
  let wrapper;
  let event;
  let returnValueSetter;

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(UnsavedChangesConfirmDialog, {
      propsData,
    });
  };

  beforeEach(() => {
    event = new Event('beforeunload');

    jest.spyOn(event, 'preventDefault');
    returnValueSetter = jest.spyOn(event, 'returnValue', 'set');
  });

  afterEach(() => {
    event.preventDefault.mockRestore();
    returnValueSetter.mockRestore();
    wrapper.destroy();
  });

  it('displays confirmation dialog when modified = true', () => {
    buildWrapper({ modified: true });
    window.dispatchEvent(event);

    expect(event.preventDefault).toHaveBeenCalled();
    expect(returnValueSetter).toHaveBeenCalledWith('');
  });

  it('does not display confirmation dialog when modified = false', () => {
    buildWrapper();
    window.dispatchEvent(event);

    expect(event.preventDefault).not.toHaveBeenCalled();
    expect(returnValueSetter).not.toHaveBeenCalled();
  });
});
