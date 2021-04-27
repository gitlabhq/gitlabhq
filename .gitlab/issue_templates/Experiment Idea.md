## Experiment summary

We believe that... {describe your hypothesis in one sentence}

To verify that, we will... {describe your test in one sentence}

And we’ll measure the impact on... {metrics}

## Hypothesis
<!-- The hypothesis represents the high-level thought process in creating the experiment but does not need to be proven in one experiment. For example, you could have a hypothesis that “users would benefit from more easily being able to start a trial” and your first experiment could fail, that doesn’t void your hypothesis only indicates you may need to think of a new iterative experiment that would still align with your hypothesis. -->

## Business problem
<!-- Where the hypothesis is focused on the user/customer, the business problem represents why/how an experiment in this area could positively impact the business. For example, trials represent a significant way for GitLab to produce valuable leads for the sales team. -->

## Supporting data
<!-- Why should we run this experiment? What’s the potential impact? Show supporting data that’s both qualitative and quantitative. Quantitative example, we generate 30,000 sign ups a month and 900 trails within 90 days (3%) with a close rate of 10% and an IACV of $400.  If we’re able to increase our trial volume by 10% percent (990 trials a month) we will generate an additional $3,600 IACV if our close rates remain constant. Qualitative example, in searching Zendesk I was able to find 10 support tickets in the last 30 days that referenced difficulties with starting a trial due to the user not being an admin. (all numbers are hypothetical and only listed for the purpose of having an example) -->

## Expected outcome
<!-- What is the expected outcome of this experiment, what metric are we trying to move? Are there any metrics we know we do not want to impact? For example, we want to impact IACV by increasing the rate at which users start trials within 30 days but we also want to ensure we don't increase the churn rate for users who've recently purchased. -->

## Experiment design & implementation
<!-- What is the experiment we’re going to run? How long do you believe it will need to run to reach significance? For example, our experiment would be to allow non-admins to request a trial through their admin, to detect a 10% change from our baseline conversion rate we’ll need a sample size of 57,000 (source Optimizely), with our current sign up rate of 30,000 a month this experiment will need to run for ~2 months. (all numbers are hypothetical and only listed for the purpose of having an example) -->

## ICE score

<!-- See https://about.gitlab.com/handbook/product/growth/#growth-ideation-and-prioritization -->

| Impact | Confidence | Ease | Score |
| ------ | ------ | ------ | ------ |
| value 1 |  value 2 |  value 3 | Average(1:3) |

## Known assumptions
<!-- This is an area to call out known assumptions in the experiment, this is especially helpful for any future colleagues that join the team so they understand other potential influences and how they were accounted for. This section is also helpful in framing possible scenarios and to keep the door open for the next steps. For example, we’re hoping our experiment will increase the number of people that start a trial but we’re assuming the conversion rate to paid and IACV will remain the same. This is a known assumption and depending on the results of the experiment could impact the direction we take on any future iterations. -->

## Results, lessons learned, next steps
<!-- What were the results of the experiment? Was the experiment a success or a failure? Based on the results should we remove the code or advocate that it become a permanent part of the experience for all users? Are there future experiments the team is going to run based off these results (include a link to new issue)? For example, our trial experiment was successful we increased the trial create rate by 10% but we saw a 1% drop in our close rate which means our net impact on IACV was negative $360 (990 * 0.09 * 400 compared tot he control of 900 * 0.1 * 400). Our next experiment (link) will focus on increasing the value once a user starts a trial. (all numbers are hypothetical and only listed for the purpose of having an example) -->


## Checklist

* [ ] Fill in the experiment summary and write more about the details of the experiment in the rest of the issue description. Some of these may be filled in through time (the "Result, learnings, next steps" section for example) but at least the experiment summary should be filled in right from the start.
* [ ] Add the label of the `group::` that will work on this experiment (if known).
* [ ] Mention the Product Manager, Engineering Manager, and at least one Product Designer from the group that owns the part of the product that the experiment will affect.
* [ ] Fill in the values in the [ICE score table](#ice-score) ping other team members for the values you aren’t confident about (i.e. engineering should almost always fill out the ease section). Add the ~"ICE Score Needed" label to indicate that the score is incomplete.
* [ ] Replace the ~"ICE Score Needed" with an ICE low/medium/high score label once all values in the ICE table have been added.
* [ ] Mention the [at]gitlab-core-team team and ask for their feedback.

/label ~"workflow::validation backlog" ~"experiment idea"
