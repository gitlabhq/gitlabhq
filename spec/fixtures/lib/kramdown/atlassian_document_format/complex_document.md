This is a complex issue…and this is normal text



* * *

Color - Dark Gray

Color - <span color="#97a0af">Light Gray</span>

Color - <span color="#6554c0">Purple</span>

Color - <span color="#00b8d9">Teal</span>

Color - <span color="#36b37e">Green</span>

Color - <span color="#ff5630">Red</span>

Color - <span color="#ff991f">Orange</span>



* * *

[https://gitlab-jira.atlassian.net/browse/DEMO-1][1]

`adf-inlineCard:
{"@context"=>"https://json-ld.org/contexts/person.jsonld",
"@id"=>"http://dbpedia.org/resource/John_Lennon", "name"=>"John Lennon",
"born"=>"1940-10-09",
"spouse"=>"http://dbpedia.org/resource/Cynthia_Lennon"}`

[External Link][2]



* * *



> This is a block quote



> \:white\_check\_mark: Success info panel

> \:information\_source: Info info panel

> \:notepad\_spiral: Note info panel

> \:warning: Warning info panel

> \:octagonal\_sign: Error info panel





* * *

@adf-mention:jhope what up



😀 🤣 🥳 😍



<table>
<tbody>
<tr>
<th>

**Col 1 Row 1**

</th>
<th>

**Col 2 Row 1**

</th>
<th>

**Col 3 Row 1**

</th>
</tr>
<tr>
<td>

Col 1 Row 2

</td>
<td>

Col 2 Row 2

</td>
<td>

Col 3 Row 2

</td>
</tr>
<tr>
<td>

Col 1 Row 3

</td>
<td>

Col 2 Row 3

</td>
<td>

Col 3 Row 3

</td>
</tr>
</tbody>
</table>


# Header 1

## Header 2

### Header 3

#### Header 4

##### Header 5

###### Header 6



* Bullet point list item 1

* Bullet point list Item 2

* Bullet point list Item 3



1.  Number list Item 1

2.  Number list item 2

3.  Number list item 3



<u>Underline</u>

<sup>Superscript</sup>

<sub>Subscript</sub>

**Bold**

*Italic*

<del>Strikethrough</del>

```javascript
export function makeIssue({ parentIssue, project, users }) {
   
  const issueType = pickRandom(project.issueTypes)

  let data = {
    fields: {
      summary: faker.lorem.sentence(),
      issuetype: {
        id: issueType.id
      },
      project: {
        id: project.id
      },
      reporter: {
        id: pickRandom(users)
      }
    }
  }

  if (issueType.subtask) {
    data = {
      parent: {
        key: parentIssue
      }
    }
  }

  console.log(data)

  return data
}
```


![jira-10050-field-description](adf-media://79411c6b-50e0-477f-b4ed-ac3a5887750c)



![jira-10050-field-description](adf-media://6a5b48c6-70bd-4747-9ac8-a9abc9adb1f4)

![jira-10050-field-description](adf-media://e818a88d-9185-4a7f-8882-18339a0f0966)





blob:[https://gitlab-jira.atlassian.net/5eb8e93b-7b15-446f-82d9-9d82ad7b8ea5#media-blob-url=true&id=572b2c1b-1b38-44ba-904a-649ee1861917&collection=upload-user-collection-426749591&contextId=10042&mimeType=image%2Fpng&name=import-jira-issues.png&size=294408][3]





[1]: https://gitlab-jira.atlassian.net/browse/DEMO-1
[2]: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25718
[3]: https://gitlab-jira.atlassian.net/5eb8e93b-7b15-446f-82d9-9d82ad7b8ea5#media-blob-url=true&id=572b2c1b-1b38-44ba-904a-649ee1861917&collection=upload-user-collection-426749591&contextId=10042&mimeType=image%2Fpng&name=import-jira-issues.png&size=294408
