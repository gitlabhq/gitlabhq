import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  SOURCE_AUTO_DEVOPS,
  MR_PIPELINE_TYPE_DETACHED,
  MR_PIPELINE_TYPE_TRAIN,
  MR_PIPELINE_TYPE_RESULT,
} from './constants';

/**
 * We reformat the graphql data here to match what we currently see in REST.
 * That way, we avoid having a lot of child components each modifying the data
 * as they need and we have a centralized place to do this transformation.
 * After the code has been fully migrated and is no longer shared between REST and graphQL apps,
 * we can safely remove this.
 *
 * @param {object} mergeRequest - GraphQL mergeRequest response object
 * @returns {object} Transformed mergeRequest data
 */
export const formatPipelinesGraphQLDataToREST = (project) => {
  const { mergeRequest } = project;
  return project?.mergeRequest?.pipelines?.nodes?.map((pipeline) => {
    return {
      ...pipeline,
      id: getIdFromGraphQLId(pipeline.id),
      commit: {
        ...pipeline.commit,
        commit_path: pipeline.commit.webPath,
        short_id: pipeline.commit.shortId,
        author_gravatar: pipeline.commit.authorGravatar,
        author_name: pipeline.commit.author.name,
        author_email: pipeline.commit.author.commitEmail,
        author: {
          avatar_url: pipeline.commit.author.avatarUrl,
          name: pipeline.commit.author.name,
          path: pipeline.commit.author.webUrl,
        },
      },
      details: {
        duration: pipeline.duration,
        status: {
          details_path: pipeline.detailedStatus.detailsPath,
          icon: `status_${pipeline.detailedStatus.name.toLowerCase()}`,
          text: capitalizeFirstCharacter(pipeline.detailedStatus.label),
          label: pipeline.detailedStatus.label,
          group: pipeline.detailedStatus.name,
          has_details: pipeline.detailedStatus.hasDetails,
        },
      },
      flags: {
        stuck: pipeline.stuck,
        auto_devops: pipeline.configSource === SOURCE_AUTO_DEVOPS,
        merge_request: true,
        yaml_errors: Boolean(pipeline.errorMessages?.nodes?.length),
        retryable: pipeline.retryable,
        cancelable: pipeline.cancelable,
        failure_reason: pipeline.failureReason,
        detached_merge_request_pipeline:
          pipeline.mergeRequestEventType === MR_PIPELINE_TYPE_DETACHED,
        merge_request_pipeline: true,
        merge_result_pipeline: pipeline.mergeRequestEventType === MR_PIPELINE_TYPE_RESULT,
        merge_train_pipeline: pipeline.mergeRequestEventType === MR_PIPELINE_TYPE_TRAIN,
        latest: pipeline.latest,
      },
      merge_request: {
        title: mergeRequest.title,
        path: mergeRequest.webPath,
        iid: mergeRequest.iid,
      },
      project: {
        full_path: project.fullPath,
      },
    };
  });
};
