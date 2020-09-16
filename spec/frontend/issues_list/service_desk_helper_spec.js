import { emptyStateHelper, generateMessages } from '~/issues_list/service_desk_helper';

describe('service desk helper', () => {
  const emptyStateMessages = generateMessages({});

  // Note: isServiceDeskEnabled must not be true when isServiceDeskSupported is false (it's an invalid case).
  describe.each`
    isServiceDeskSupported | isServiceDeskEnabled | canEditProjectSettings | expectedMessage
    ${true}                | ${true}              | ${true}                | ${'serviceDeskEnabledAndCanEditProjectSettings'}
    ${true}                | ${true}              | ${false}               | ${'serviceDeskEnabledAndCannotEditProjectSettings'}
    ${true}                | ${false}             | ${true}                | ${'serviceDeskDisabledAndCanEditProjectSettings'}
    ${true}                | ${false}             | ${false}               | ${'serviceDeskDisabledAndCannotEditProjectSettings'}
    ${false}               | ${false}             | ${true}                | ${'serviceDeskIsNotSupported'}
    ${false}               | ${false}             | ${false}               | ${'serviceDeskIsNotEnabled'}
  `(
    'isServiceDeskSupported = $isServiceDeskSupported, isServiceDeskEnabled = $isServiceDeskEnabled, canEditProjectSettings = $canEditProjectSettings',
    ({ isServiceDeskSupported, isServiceDeskEnabled, canEditProjectSettings, expectedMessage }) => {
      it(`displays ${expectedMessage} message`, () => {
        const emptyStateMeta = {
          isServiceDeskEnabled,
          isServiceDeskSupported,
          canEditProjectSettings,
        };
        expect(emptyStateHelper(emptyStateMeta)).toEqual(emptyStateMessages[expectedMessage]);
      });
    },
  );
});
