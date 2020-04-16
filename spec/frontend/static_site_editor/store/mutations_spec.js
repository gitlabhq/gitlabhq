import createState from '~/static_site_editor/store/state';
import mutations from '~/static_site_editor/store/mutations';
import * as types from '~/static_site_editor/store/mutation_types';
import {
  sourceContentTitle as title,
  sourceContent as content,
  savedContentMeta,
  submitChangesError,
} from '../mock_data';

describe('Static Site Editor Store mutations', () => {
  let state;
  const contentLoadedPayload = { title, content };

  beforeEach(() => {
    state = createState();
  });

  it.each`
    mutation                              | stateProperty           | payload                 | expectedValue
    ${types.LOAD_CONTENT}                 | ${'isLoadingContent'}   | ${undefined}            | ${true}
    ${types.RECEIVE_CONTENT_SUCCESS}      | ${'isLoadingContent'}   | ${contentLoadedPayload} | ${false}
    ${types.RECEIVE_CONTENT_SUCCESS}      | ${'isContentLoaded'}    | ${contentLoadedPayload} | ${true}
    ${types.RECEIVE_CONTENT_SUCCESS}      | ${'title'}              | ${contentLoadedPayload} | ${title}
    ${types.RECEIVE_CONTENT_SUCCESS}      | ${'content'}            | ${contentLoadedPayload} | ${content}
    ${types.RECEIVE_CONTENT_SUCCESS}      | ${'originalContent'}    | ${contentLoadedPayload} | ${content}
    ${types.RECEIVE_CONTENT_ERROR}        | ${'isLoadingContent'}   | ${undefined}            | ${false}
    ${types.SET_CONTENT}                  | ${'content'}            | ${content}              | ${content}
    ${types.SUBMIT_CHANGES}               | ${'isSavingChanges'}    | ${undefined}            | ${true}
    ${types.SUBMIT_CHANGES_SUCCESS}       | ${'savedContentMeta'}   | ${savedContentMeta}     | ${savedContentMeta}
    ${types.SUBMIT_CHANGES_SUCCESS}       | ${'isSavingChanges'}    | ${savedContentMeta}     | ${false}
    ${types.SUBMIT_CHANGES_ERROR}         | ${'isSavingChanges'}    | ${undefined}            | ${false}
    ${types.SUBMIT_CHANGES_ERROR}         | ${'submitChangesError'} | ${submitChangesError}   | ${submitChangesError}
    ${types.DISMISS_SUBMIT_CHANGES_ERROR} | ${'submitChangesError'} | ${undefined}            | ${''}
  `(
    '$mutation sets $stateProperty to $expectedValue',
    ({ mutation, stateProperty, payload, expectedValue }) => {
      mutations[mutation](state, payload);
      expect(state[stateProperty]).toBe(expectedValue);
    },
  );

  it(`${types.SUBMIT_CHANGES_SUCCESS} sets originalContent to content current value`, () => {
    const editedContent = `${content} plus something else`;

    state = createState({
      originalContent: content,
      content: editedContent,
    });
    mutations[types.SUBMIT_CHANGES_SUCCESS](state);

    expect(state.originalContent).toBe(state.content);
  });
});
