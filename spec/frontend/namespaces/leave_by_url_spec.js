import leaveByUrl, { NAMESPACE_TYPES } from '~/namespaces/leave_by_url';
import { createAlert } from '~/alert';
import { initRails } from '~/lib/utils/rails_ujs';
import * as urlUtility from '~/lib/utils/url_utility';
import { waitForElement } from '~/lib/utils/dom_utils';

jest.mock('~/alert');
jest.mock('~/lib/utils/rails_ujs', () => ({
  initRails: jest.fn(),
}));
jest.mock('~/lib/utils/url_utility');
jest.mock('~/lib/utils/dom_utils');

describe('leaveByUrl', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('throws an error if namespaceType is not provided', async () => {
    await expect(leaveByUrl()).rejects.toThrow('namespaceType not provided');
  });

  it('returns early if leave parameter is not in URL', async () => {
    jest.spyOn(urlUtility, 'getParameterByName').mockReturnValue(null);

    await leaveByUrl(NAMESPACE_TYPES.PROJECT);

    expect(initRails).not.toHaveBeenCalled();
    expect(waitForElement).not.toHaveBeenCalled();
  });

  describe('when leave parameter is present', () => {
    beforeEach(() => {
      jest.spyOn(urlUtility, 'getParameterByName').mockReturnValue('1');
    });

    it('initializes Rails UJS', async () => {
      const mockLeaveLink = { click: jest.fn() };
      waitForElement.mockResolvedValue(mockLeaveLink);

      await leaveByUrl(NAMESPACE_TYPES.PROJECT);

      expect(initRails).toHaveBeenCalled();
    });

    it('waits for project leave link and clicks it', async () => {
      const mockLeaveLink = { click: jest.fn() };
      waitForElement.mockResolvedValue(mockLeaveLink);

      await leaveByUrl(NAMESPACE_TYPES.PROJECT);

      expect(waitForElement).toHaveBeenCalledWith('.js-leave-link');
      expect(mockLeaveLink.click).toHaveBeenCalled();
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('waits for group leave link and clicks it', async () => {
      const mockLeaveLink = { click: jest.fn() };
      waitForElement.mockResolvedValue(mockLeaveLink);

      await leaveByUrl(NAMESPACE_TYPES.GROUP);

      expect(waitForElement).toHaveBeenCalledWith('#group-more-action-dropdown .js-leave-link');
      expect(mockLeaveLink.click).toHaveBeenCalled();
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('shows permission error when element timeout occurs', async () => {
      waitForElement.mockRejectedValue(new Error('Some error'));

      await leaveByUrl(NAMESPACE_TYPES.PROJECT);

      expect(createAlert).toHaveBeenCalledWith({
        message: 'You do not have permission to leave this project.',
      });
    });
  });
});
