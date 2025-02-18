import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import DiffFileDrafts from '~/batch_comments/components/diff_file_drafts.vue';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { useBatchComments } from '~/batch_comments/store';
import * as mockData from '../../notes/mock_data';

Vue.use(PiniaVuePlugin);

describe('Batch comments diff file drafts component', () => {
  let wrapper;
  let pinia;

  function factory(propsData = {}) {
    wrapper = shallowMount(DiffFileDrafts, {
      pinia,
      propsData: { fileHash: 'filehash', positionType: 'file', ...propsData },
    });
  }

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
    useBatchComments().drafts = [
      ...mockData.draftComments.map((draft) => ({
        ...draft,
        file_hash: 'filehash',
        position: { position_type: 'file' },
      })),
    ];
  });

  it('renders list of draft notes', () => {
    factory();

    expect(wrapper.findAllComponents(DraftNote).length).toEqual(2);
  });

  it('renders index of draft note', () => {
    factory();

    const elements = wrapper.findAllComponents(DesignNotePin);

    expect(elements.length).toEqual(2);

    expect(elements.at(0).props('label')).toEqual(1);

    expect(elements.at(1).props('label')).toEqual(2);
  });

  it('passes down autosaveKey prop to draft note', () => {
    const autosaveKey = 'autosave';
    factory({ autosaveKey });

    expect(wrapper.findComponent(DraftNote).props('autosaveKey')).toEqual(autosaveKey);
  });
});
