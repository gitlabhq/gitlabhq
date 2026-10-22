import setConfigs from '@gitlab/duo-ui/dist/config';

jest.mock('@gitlab/duo-ui/dist/config', () => ({ __esModule: true, default: jest.fn() }));
jest.mock('~/locale', () => ({
  __: jest.fn((str) => str),
  s__: jest.fn((str) => str),
}));

describe('Duo UI configuration', () => {
  it('calls setConfigs with translations', async () => {
    await import('~/commons/duo_ui');

    expect(setConfigs).toHaveBeenCalledTimes(1);
    expect(setConfigs).toHaveBeenCalledWith(
      expect.objectContaining({
        translations: expect.objectContaining({
          'DuoChat.chatTitle': expect.any(String),
          'DuoChat.chatCancelLabel': expect.any(String),
          'WebDuoChat.chatDefaultTitle': expect.any(String),
          'AgenticDuoChat.chatDefaultTitle': expect.any(String),
          'WebAgenticDuoChat.chatDefaultTitle': expect.any(String),
          Yes: expect.any(String),
          No: expect.any(String),
        }),
      }),
    );
  });
});
