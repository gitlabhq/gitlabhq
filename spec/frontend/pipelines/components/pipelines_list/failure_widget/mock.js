export const job = {
  id: 'gid://gitlab/Ci::Build/5241',
  allowFailure: false,
  detailedStatus: {
    id: 'status',
    action: {
      id: 'action',
      path: '/retry',
      icon: 'retry',
    },
    group: 'running',
    icon: 'running-icon',
  },
  name: 'job-name',
  retried: false,
  stage: {
    id: '1',
    name: 'build',
  },
  trace: {
    htmlSummary:
      '<span>To install the missing version, run `gem install bundler:2.4.13`<br/>\tfrom /System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/2.6.0/rubygems.rb:302:in `activate_bin_path\'<br/>\tfrom /usr/bin/bundle:23:in `&lt;main>\'<br/></span><div class="section-start" data-timestamp="1685044123" data-section="upload-artifacts-on-failure" role="button"></div><span class="term-fg-l-cyan term-bold section section-header js-s-upload-artifacts-on-failure">Uploading artifacts for failed job</span><span class="section section-header js-s-upload-artifacts-on-failure"><br/></span><span class="term-fg-l-green term-bold section line js-s-upload-artifacts-on-failure">Uploading artifacts...</span><span class="section line js-s-upload-artifacts-on-failure"><br/>Runtime platform                                  </span><span class="section line js-s-upload-artifacts-on-failure">  arch</span><span class="section line js-s-upload-artifacts-on-failure">=arm64 os</span><span class="section line js-s-upload-artifacts-on-failure">=darwin pid</span><span class="section line js-s-upload-artifacts-on-failure">=16706 revision</span><span class="section line js-s-upload-artifacts-on-failure">=43b2dc3d version</span><span class="section line js-s-upload-artifacts-on-failure">=15.4.0<br/></span><span class="term-fg-yellow section line js-s-upload-artifacts-on-failure">WARNING: rspec.xml: no matching files. Ensure that the artifact path is relative to the working directory</span><span class="section line js-s-upload-artifacts-on-failure"> <br/></span><span class="term-fg-l-red term-bold section line js-s-upload-artifacts-on-failure">ERROR: No files to upload                         </span><span class="section line js-s-upload-artifacts-on-failure"> <br/></span><div class="section-end" data-section="upload-artifacts-on-failure"></div><span class="term-fg-l-red term-bold">ERROR: Job failed: exit status 1<br/></span><span><br/></span>',
  },
  webPath: '/',
};

export const allowedToFailJob = {
  ...job,
  id: 'gid://gitlab/Ci::Build/5242',
  allowFailure: true,
};

export const failedJobsMock = {
  data: {
    project: {
      id: 'gid://gitlab/Project/20',
      pipeline: {
        id: 'gid://gitlab/Pipeline/20',
        jobs: {
          nodes: [allowedToFailJob, job],
        },
      },
    },
  },
};
