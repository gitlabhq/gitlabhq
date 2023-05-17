import { shallowMount } from '@vue/test-utils';
import ConfirmDialog from '~/ci/pipeline_editor/components/ui/confirm_unsaved_changes_dialog.vue';

describe('pipeline_editor/components/ui/confirm_unsaved_changes_dialog', () => {
  let beforeUnloadEvent;
  let setDialogContent;

  const createComponent = (propsData = {}) => {
    shallowMount(ConfirmDialog, {
      propsData,
    });
  };

  beforeEach(() => {
    beforeUnloadEvent = new Event('beforeunload');
    jest.spyOn(beforeUnloadEvent, 'preventDefault');
    setDialogContent = jest.spyOn(beforeUnloadEvent, 'returnValue', 'set');
  });

  afterEach(() => {
    beforeUnloadEvent.preventDefault.mockRestore();
    setDialogContent.mockRestore();
  });

  it('shows confirmation dialog when there are unsaved changes', () => {
    createComponent({ hasUnsavedChanges: true });
    window.dispatchEvent(beforeUnloadEvent);

    expect(beforeUnloadEvent.preventDefault).toHaveBeenCalled();
    expect(setDialogContent).toHaveBeenCalledWith('');
  });

  it('does not show confirmation dialog when there are no unsaved changes', () => {
    createComponent({ hasUnsavedChanges: false });
    window.dispatchEvent(beforeUnloadEvent);

    expect(beforeUnloadEvent.preventDefault).not.toHaveBeenCalled();
    expect(setDialogContent).not.toHaveBeenCalled();
  });
});
