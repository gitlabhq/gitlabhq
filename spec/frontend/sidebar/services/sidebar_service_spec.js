import SidebarService, { gqClient } from '~/sidebar/services/sidebar_service';
import reviewerRereviewMutation from 'ee_else_ce/sidebar/queries/reviewer_rereview.mutation.graphql';

describe('SidebarService', () => {
  let service;

  beforeEach(() => {
    service = new SidebarService({ fullPath: 'group/project', iid: 1 });
    jest.spyOn(gqClient, 'mutate').mockResolvedValue({});
  });

  afterEach(() => {
    SidebarService.singleton = null;
  });

  describe('requestReview', () => {
    it('sends no depth when none is chosen', () => {
      service.requestReview(5);

      expect(gqClient.mutate).toHaveBeenCalledWith({
        mutation: reviewerRereviewMutation,
        variables: {
          userId: 'gid://gitlab/User/5',
          projectPath: 'group/project',
          iid: '1',
          duoCodeReviewDepth: undefined,
        },
      });
    });

    it('sends the chosen depth', () => {
      service.requestReview(5, 'DEEP');

      expect(gqClient.mutate).toHaveBeenCalledWith({
        mutation: reviewerRereviewMutation,
        variables: {
          userId: 'gid://gitlab/User/5',
          projectPath: 'group/project',
          iid: '1',
          duoCodeReviewDepth: 'DEEP',
        },
      });
    });
  });
});
