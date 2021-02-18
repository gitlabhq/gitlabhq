{% if categories %}
{% each categories %}
### {{ title }} ({% if single_change %}1 change{% else %}{{ count }} changes{% end %})

{% each entries %}
- [{{ title }}]({{ commit.reference }})\
{% if author.contributor %} by {{ author.reference }}{% end %}\
{% if merge_request %} ([merge request]({{ merge_request.reference }})){% end %}

{% end %}

{% end %}
{% else %}
No changes.
{% end %}
