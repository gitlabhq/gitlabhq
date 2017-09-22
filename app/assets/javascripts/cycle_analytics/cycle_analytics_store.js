import { __ } from '../locale';
import '../lib/utils/text_utility';
import DEFAULT_EVENT_OBJECTS from './default_event_objects';

export default class CycleAnalyticsStore {
  constructor() {
    this.state = {
      summary: [],
      analytics: {},
      events: [],
      stages: [],
    };

    this.EMPTY_STAGE_TEXTS = {
      issue: __('The issue stage shows the time it takes from creating an issue to assigning the issue to a milestone, or add the issue to a list on your Issue Board. Begin creating issues to see data for this stage.'),
      plan: __('The planning stage shows the time from the previous step to pushing your first commit. This time will be added automatically once you push your first commit.'),
      code: __('The coding stage shows the time from the first commit to creating the merge request. The data will automatically be added here once you create your first merge request.'),
      test: __('The testing stage shows the time GitLab CI takes to run every pipeline for the related merge request. The data will automatically be added after your first pipeline finishes running.'),
      review: __('The review stage shows the time from creating the merge request to merging it. The data will automatically be added after you merge your first merge request.'),
      staging: __('The staging stage shows the time between merging the MR and deploying code to the production environment. The data will be automatically added once you deploy to production for the first time.'),
      production: __('The production stage shows the total time it takes between creating an issue and deploying the code to production. The data will be automatically added once you have completed the full idea to production cycle.'),
    };
  }

  setCycleAnalyticsData(data) {
    debugger;
    const summary = data.summary.map(item => Object.assign({}, item, { value: item.value || '-' }));
    const stages = data.stats.map((el) => {
      const stageSlug = gl.text.dasherize(el.name.toLowerCase());

      return Object.assign({}, el, {
        active: false,
        isUserAllowed: data.permissions[stageSlug],
        emptyStageText: this.EMPTY_STAGE_TEXTS[stageSlug],
        component: `stage-${stageSlug}-component`,
        slug: stageSlug,
      });
    });

    this.state = Object.assign(this.state, {
      stages: stages || [],
      summary: summary || [],
      analytics: data,
    });
  }

  setLoadingState(state) {
    this.state.isLoading = state;
  }

  setErrorState(state) {
    this.state.hasError = state;
  }

  deactivateAllStages() {
    this.state.stages = this.state.stages.map(stage => Object.assign({}, stage, { active: false }));
  }

  setActiveStage(stage) {
    this.deactivateAllStages();
    this.state.stages.find(state => state.name === stage.name).active = true;
  }

  setStageEvents(events, stage) {
    this.state.events = events.map((event) => {
      if (event) {
        return Object.assign({}, DEFAULT_EVENT_OBJECTS[stage.slug], event, {
          totalTime: event.total_time,
          author: event.author ? {
            webUrl: event.author.web_url,
            avatarUrl: event.author.avatar_url,
          } : {},
          createdAt: event.created_at,
          shortSha: event.short_sha,
          commitUrl: event.commit_url,
        });
      }
      return event;
    });
  }

  currentActiveStage() {
    return this.state.stages.find(stage => stage.active);
  }
}
