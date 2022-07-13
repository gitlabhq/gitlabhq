import { s__ } from '~/locale';

export const timelineTabI18n = Object.freeze({
  title: s__('Incident|Timeline'),
  emptyDescription: s__('Incident|No timeline items have been added yet.'),
  addEventButton: s__('Incident|Add new timeline event'),
});

export const timelineFormI18n = Object.freeze({
  createError: s__('Incident|Error creating incident timeline event: %{error}'),
  areaPlaceholder: s__('Incident|Timeline text...'),
  saveAndAdd: s__('Incident|Save and add another event'),
  areaLabel: s__('Incident|Timeline text'),
});
