/* eslint-disable no-param-reassign */
(() => {
  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};

  gl.environmentsList.EnvironmentsStore = {
    state: {},

    create() {
      this.state.environments = [];
      this.state.stoppedCounter = 0;
      this.state.availableCounter = 0;

      return this;
    },

    /**
     * In order to display a tree view we need to modify the received
     * data in to a tree structure based on `environment_type`
     * sorted alphabetically.
     * In each children a `vue-` property will be added. This property will be
     * used to know if an item is a children mostly for css purposes. This is
     * needed because the children row is a fragment instance and therfore does
     * not accept non-prop attributes.
     *
     *
     * @example
     * it will transform this:
     * [
     *   { name: "environment", environment_type: "review" },
     *   { name: "environment_1", environment_type: null }
     *   { name: "environment_2, environment_type: "review" }
     * ]
     * into this:
     * [
     *   { name: "review", children:
     *      [
     *        { name: "environment", environment_type: "review", vue-isChildren: true},
     *        { name: "environment_2", environment_type: "review", vue-isChildren: true}
     *      ]
     *   },
     *  {name: "environment_1", environment_type: null}
     * ]
     *
     *
     * @param  {Array} environments List of environments.
     * @returns {Array} Tree structured array with the received environments.
     */
    storeEnvironments(environments = []) {
      environments = [{
	"id": 31,
	"name": "production",
	"state": "stopped",
	"external_url": null,
	"environment_type": null,
	"last_deployment": {
		"id": 66,
		"iid": 6,
		"sha": "500aabcb17c97bdcf2d0c410b70cb8556f0362dd",
		"ref": {
			"name": "master",
			"ref_path": "/root/ci-folders/tree/master"
		},
		"tag": false,
		"last?": true,
		"user": {
			"name": "Administrator",
			"username": "root",
			"id": 1,
			"state": "active",
			"avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
			"web_url": "http://localhost:3000/root"
		},
		"commit": {
			"id": "500aabcb17c97bdcf2d0c410b70cb8556f0362dd",
			"short_id": "500aabcb",
			"title": "Update .gitlab-ci.yml",
			"author_name": "Administrator",
			"author_email": "admin@example.com",
			"created_at": "2016-11-07T18:28:13.000+00:00",
			"message": "Update .gitlab-ci.yml",
			"author": {
				"name": "Administrator",
				"username": "root",
				"id": 1,
				"state": "active",
				"avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
				"web_url": "http://localhost:3000/root"
			},
			"commit_path": "/root/ci-folders/tree/500aabcb17c97bdcf2d0c410b70cb8556f0362dd"
		},
		"deployable": {
			"id": 1279,
			"name": "deploy",
			"build_path": "/root/ci-folders/builds/1279",
			"retry_path": "/root/ci-folders/builds/1279/retry"
		},
		"manual_actions": []
	},
	"stoppable?": false,
	"environment_path": "/root/ci-folders/environments/31",
	"created_at": "2016-11-07T11:11:16.525Z",
	"updated_at": "2016-11-10T15:55:58.778Z"
}, {
	"id": 33,
	"name": "folder/foo",
	"state": "available",
	"external_url": "http://bar.filipa.com",
	"environment_type": "folder",
	"last_deployment": {
		"id": 66,
		"iid": 6,
		"sha": "500aabcb17c97bdcf2d0c410b70cb8556f0362dd",
		"ref": {
			"name": "master",
			"ref_path": "/root/ci-folders/tree/master"
		},
		"tag": false,
		"last?": true,
		"user": {
			"name": "Administrator",
			"username": "root",
			"id": 1,
			"state": "active",
			"avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
			"web_url": "http://localhost:3000/root"
		},
		"commit": {
			"id": "500aabcb17c97bdcf2d0c410b70cb8556f0362dd",
			"short_id": "500aabcb",
			"title": "Real big commi message adasdasdas asdasd sd sdsdfdsf Update .gitlab-ci.yml",
			"author_name": "Administrator",
			"author_email": "admin@example.com",
			"created_at": "2016-11-07T18:28:13.000+00:00",
			"message": "Update .gitlab-ci.yml",
			"author": {
				"name": "Administrator",
				"username": "root",
				"id": 1,
				"state": "active",
				"avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
				"web_url": "http://localhost:3000/root"
			},
			"commit_path": "/root/ci-folders/tree/500aabcb17c97bdcf2d0c410b70cb8556f0362dd"
		},
		"deployable": {
			"id": 1279,
			"name": "deploy",
			"build_path": "/root/ci-folders/builds/1279",
			"retry_path": "/root/ci-folders/builds/1279/retry"
		},
		"manual_actions": []
	},
	"stoppable?": false,
	"environment_path": "/root/ci-folders/environments/33",
	"created_at": "2016-11-07T11:17:20.604Z",
	"updated_at": "2016-11-07T11:17:20.604Z"
}, {
	"id": 34,
	"name": "folder/bar",
	"last_deployment": {
		"id": 66,
		"iid": 6,
		"sha": "500aabcb17c97bdcf2d0c410b70cb8556f0362dd",
		"ref": {
			"name": "master",
			"ref_path": "/root/ci-folders/tree/master"
		},
		"tag": false,
		"last?": true,
		"user": {
			"name": "Administrator",
			"username": "root",
			"id": 1,
			"state": "active",
			"avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
			"web_url": "http://localhost:3000/root"
		},
		"commit": {
			"id": "500aabcb17c97bdcf2d0c410b70cb8556f0362dd",
			"short_id": "500aabcb",
			"title": "Update .gitlab-ci.yml",
			"author_name": "Administrator",
			"author_email": "admin@example.com",
			"created_at": "2016-11-07T18:28:13.000+00:00",
			"message": "Update .gitlab-ci.yml",
			"author": {
				"name": "Administrator",
				"username": "root",
				"id": 1,
				"state": "active",
				"avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
				"web_url": "http://localhost:3000/root"
			},
			"commit_path": "/root/ci-folders/tree/500aabcb17c97bdcf2d0c410b70cb8556f0362dd"
		},
		"deployable": {
			"id": 1279,
			"name": "deploy",
			"build_path": "/root/ci-folders/builds/1279",
			"retry_path": "/root/ci-folders/builds/1279/retry"
		},
		"manual_actions": []
	},
	"state": "available",
	"external_url": null,
	"environment_type": "folder",

	"stoppable?": false,
	"environment_path": "/root/ci-folders/environments/34",
	"created_at": "2016-11-07T11:31:59.481Z",
	"updated_at": "2016-11-07T11:31:59.481Z"
}, {
	"id": 35,
	"name": "review",
	"state": "available",
	"external_url": null,
	"environment_type": null,
	"last_deployment": {
		"id": 67,
		"iid": 7,
		"sha": "9dcecbafd2514b555ad2ef9be1f40c6b46009613",
		"ref": {
			"name": "master",
			"ref_path": "/root/ci-folders/tree/master"
		},
		"tag": false,
		"last?": true,
		"user": {
			"name": "Administrator",
			"username": "root",
			"id": 1,
			"state": "active",
			"avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
			"web_url": "http://localhost:3000/root"
		},
		"commit": {
			"id": "9dcecbafd2514b555ad2ef9be1f40c6b46009613",
			"short_id": "9dcecbaf",
			"title": "aa Update .gitlab-ci.yml",
			"author_name": "Administrator",
			"author_email": "admin@example.com",
			"created_at": "2016-11-09T15:53:06.000+00:00",
			"message": "aa Update .gitlab-ci.yml",
			"author": {
				"name": "Administrator",
				"username": "root",
				"id": 1,
				"state": "active",
				"avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
				"web_url": "http://localhost:3000/root"
			},
			"commit_path": "/root/ci-folders/tree/9dcecbafd2514b555ad2ef9be1f40c6b46009613"
		},
		"deployable": {
			"id": 1283,
			"name": "test",
			"build_path": "/root/ci-folders/builds/1283",
			"retry_path": "/root/ci-folders/builds/1283/retry"
		},
		"manual_actions": [{
			"id": 1292,
			"name": "stop_review_app",
			"build_path": "/root/ci-folders/builds/1292",
			"retry_path": "/root/ci-folders/builds/1292/retry",
			"play_path": "/root/ci-folders/builds/1292/play"
		}]
	},
	"stoppable?": true,
	"environment_path": "/root/ci-folders/environments/35",
	"created_at": "2016-11-09T15:53:45.108Z",
	"updated_at": "2016-11-09T15:53:45.108Z"
}, {
	"id": 36,
	"name": "review",
	"state": "stopped",
	"external_url": null,
	"environment_type": null,
	"last_deployment": null,
	"stoppable?": false,
	"environment_path": "/root/ci-folders/environments/36",
	"created_at": "2016-11-09T15:53:45.220Z",
	"updated_at": "2016-11-09T15:53:45.273Z"
}];

      this.state.stoppedCounter = this.countByState(environments, 'stopped');
      this.state.availableCounter = this.countByState(environments, 'available');

      const environmentsTree = environments.reduce((acc, environment) => {
        if (environment.environment_type !== null) {
          const occurs = acc.filter(element => element.children &&
             element.name === environment.environment_type);

          environment['vue-isChildren'] = true;

          if (occurs.length) {
            acc[acc.indexOf(occurs[0])].children.push(environment);
            acc[acc.indexOf(occurs[0])].children.sort(this.sortByName);
          } else {
            acc.push({
              name: environment.environment_type,
              children: [environment],
              isOpen: false,
              'vue-isChildren': environment['vue-isChildren'],
            });
          }
        } else {
          acc.push(environment);
        }

        return acc;
      }, []).sort(this.sortByName);

      this.state.environments = environmentsTree;

      return environmentsTree;
    },

    /**
     * Toggles folder open property given the environment type.
     *
     * @param  {String} envType
     * @return {Array}
     */
    toggleFolder(envType) {
      const environments = this.state.environments;

      const environmnetsCopy = environments.map((env) => {
        if (env['vue-isChildren'] === true && env.name === envType) {
          env.isOpen = !env.isOpen;
        }

        return env;
      });

      this.state.environments = environmnetsCopy;

      return environmnetsCopy;
    },

    /**
     * Given an array of environments, returns the number of environments
     * that have the given state.
     *
     * @param  {Array} environments
     * @param  {String} state
     * @returns {Number}
     */
    countByState(environments, state) {
      return environments.filter(env => env.state === state).length;
    },

    /**
     * Sorts the two objects provided by their name.
     *
     * @param  {Object} a
     * @param  {Object} b
     * @returns {Number}
     */
    sortByName(a, b) {
      const nameA = a.name.toUpperCase();
      const nameB = b.name.toUpperCase();

      if (nameA < nameB) {
        return -1;
      }

      if (nameA > nameB) {
        return 1;
      }

      return 0;
    },
  };
})();
